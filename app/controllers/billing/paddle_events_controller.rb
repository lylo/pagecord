require "openssl"

module Billing
  class PaddleEventsController < ApplicationController
    skip_forgery_protection
    skip_before_action :authenticate, :domain_check

    PADDLE_CONFIG = Rails.application.config_for(:paddle)

    HANDLERS = {
      "subscription.created" => :subscription_created,
      "subscription.updated" => :subscription_updated,
      "subscription.canceled" => :subscription_canceled,
      "subscription.past_due" => :subscription_past_due,
      "transaction.completed" => :transaction_completed,
      "transaction.payment_failed" => :transaction_payment_failed
    }.freeze

    def create
      if verify_signature
        if @user = load_user
          process_event params[:event_type]
        else
          Rails.logger.warn("Unable to find user for Paddle #{params[:event_type]} (customer #{params.dig(:data, :customer_id)})")
        end
      else
        Rails.logger.error("Unable to verify Paddle request signature")
      end

      head :ok
    end

    private

      def verify_signature
        paddle_signature = request.headers["Paddle-Signature"]
        ts_part, h1_part = paddle_signature.to_s.split(";")
        var, ts = ts_part.to_s.split("=")
        var, h1 = h1_part.to_s.split("=")
        return false if ts.blank? || h1.blank?

        signed_payload = "#{ts}:#{request.raw_post}"

        key = PADDLE_CONFIG[:webhook_secret_key]
        data = signed_payload
        digest = OpenSSL::Digest.new("sha256")
        hmac = OpenSSL::HMAC.hexdigest(digest, key, data)

        ActiveSupport::SecurityUtils.secure_compare(hmac, h1)
      end

      def load_user
        if (user_id = payload.user_id).present?
          @user = User.find_by(id: user_id.to_i)
          @subscription = @user&.subscription
        end

        # Fall back to the customer when custom_data is missing or does not resolve,
        # rather than dropping the event and leaving the subscription stale.
        if @user.nil? && payload.customer_id.present?
          @subscription = Subscription.find_by(paddle_customer_id: payload.customer_id)
          @user = @subscription&.user
        end

        @user
      end

      def process_event(event)
        PaddleEvent.create!(user: @user, payload: params)

        Rails.logger.info "Paddle #{event} for user #{@user.id}"

        handler = HANDLERS[event]
        send(handler) if handler
      end

      def subscription_created
        plan = detect_plan
        @subscription = @user.subscription || Subscription.create!(user: @user, plan: plan)

        Rails.logger.info "New subscription #{@user.id} (subscription id: #{@subscription.id})"
        if @subscription.cancelled?
          Rails.logger.info "Subscription #{@subscription.id} was previously cancelled. Creating new subscription"

          # this is a re-activation of an existing subscription. delete and recreate
          @subscription.destroy!
          @subscription = Subscription.create!(user: @user, plan: plan)
          Rails.logger.info "New subscription #{@subscription.id} created for @#{@user.id}"
        end

        @subscription.update!(
          paddle_subscription_id: payload.subscription_id,
          paddle_customer_id: payload.customer_id,
          paddle_price_id: payload.price_id,
          unit_price: payload.unit_price,
          next_billed_at: Time.parse(payload.next_billed_at),
          plan: plan
        )

        Subscription::SupporterWelcomeMailer.welcome(@subscription).deliver_later if @subscription.supporter?
      end

      def subscription_canceled
        cancelled_at = Time.parse(payload.canceled_at)

        Rails.logger.info "Subscription #{@subscription.id} cancelled at #{cancelled_at}"

        # Paddle only sends this once the cancellation has taken effect, so access ends
        # now. Cancellations scheduled for the end of the term arrive as
        # subscription.updated with a scheduled_change and keep their billing period
        # until this event follows.
        @subscription.update!(cancelled_at: cancelled_at, next_billed_at: cancelled_at)
      end

      def subscription_updated
        Rails.logger.info "Subscription #{@subscription.id} updated"

        next_billed_at = @subscription.next_billed_at
        if payload.next_billed_at.present?
          next_billed_at = Time.parse(payload.next_billed_at)
        end

        new_price_id = payload.price_id
        new_plan = Subscription.plan_from_price_id(new_price_id)

        Rails.logger.info "Subscription next billed at updated to #{next_billed_at}, plan: #{new_plan}"
        @subscription.update!(
          paddle_price_id: new_price_id,
          unit_price: payload.unit_price,
          next_billed_at: next_billed_at,
          plan: new_plan
        )

        notify_supporter_upgrade

        if (cancelling_at = payload.cancellation_scheduled_at)
          Rails.logger.info "Subscription is being cancelled"
          @subscription.update!(cancelled_at: Time.parse(cancelling_at))
        end
      end

      def subscription_past_due
        # No-op
        Rails.logger.info "Subscription past due"
      end

      def transaction_completed
        Rails.logger.info "Transaction completed. Updating next_billed_at and unit_price"

        return if payload.origin == "subscription_payment_method_change"

        billing_period_ends_at = payload.billing_period_ends_at

        unless billing_period_ends_at.present?
          Rails.logger.error "No next_billed_at in transaction_completed event"
          raise "No next_billed_at in transaction_completed event for #{@user.id} (#{@user.blog.subdomain})"
        end

        if @subscription.present?
          next_billed_at = Time.parse(billing_period_ends_at)

          updates = {
            next_billed_at: next_billed_at,
            unit_price: payload.transaction_unit_price
          }

          if payload.origin == "subscription_update" && (new_price_id = payload.changed_plan_price_id)
            updates[:paddle_price_id] = new_price_id
            updates[:plan] = Subscription.plan_from_price_id(new_price_id)
            # On a plan switch, the transaction's line-item total is the prorated
            # top-up charged today, not the ongoing recurring price. Store the new
            # price's list price instead, so it matches what the next full renewal bills.
            updates[:unit_price] = payload.changed_plan_unit_price
            Rails.logger.info "Plan changed to #{updates[:plan]} (price_id: #{new_price_id})"
          end

          @subscription.update!(updates)

          notify_supporter_upgrade

          Rails.logger.info "Subscription #{@subscription.id} next billed on #{next_billed_at}, unit_price: #{updates[:unit_price]}"
        else
          raise "Subscription not found for transaction_completed event for #{@user.id} (#{@user.blog.subdomain})"
        end
      end

      def transaction_payment_failed
        Rails.logger.warn "Payment failed for user #{@user.id} (#{@user.blog.subdomain}) - Paddle Retain will retry automatically"
      end

      # Fires only on the save that actually flips the plan to supporter, so the
      # two webhooks Paddle sends for a single plan change do not double-send.
      def notify_supporter_upgrade
        return unless @subscription.saved_change_to_plan? && @subscription.supporter?

        Subscription::SupporterWelcomeMailer.welcome(@subscription).deliver_later
      end

      def detect_plan
        return payload.checkout_plan if payload.checkout_plan.present?

        payload.monthly_billing_cycle? ? "monthly" : "annual"
      end

      def payload
        @payload ||= PaddlePayload.new(params[:data], params[:event_type])
      end
  end
end
