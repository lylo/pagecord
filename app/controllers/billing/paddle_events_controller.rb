require "openssl"
require "ostruct"

module Billing
  class PaddleEventsController < ApplicationController
    skip_forgery_protection
    skip_before_action :authenticate, :domain_check

    PADDLE_CONFIG = Rails.application.config_for(:paddle)

    def create
      if verify_signature
        if @user = load_user
          process_event params[:event_type]
        else
          Rails.logger.warn("Unable to find user for Paddle Event")
        end
      else
        Rails.logger.error("Unable to verify Paddle request signature")
      end

      head :ok
    end

    private

      def verify_signature
        paddle_signature = request.headers["Paddle-Signature"]
        ts_part, h1_part = paddle_signature.split(";")
        var, ts = ts_part.split("=")
        var, h1 = h1_part.split("=")

        signed_payload = "#{ts}:#{request.raw_post}"

        key = PADDLE_CONFIG[:webhook_secret_key]
        data = signed_payload
        digest = OpenSSL::Digest.new("sha256")
        hmac = OpenSSL::HMAC.hexdigest(digest, key, data)

        hmac == h1
      end

      def load_user
        if data.custom_data.present?
          @user = User.find_by(id: data.custom_data.user_id.to_i)
          @subscription = @user&.subscription
        elsif data.customer_id
          @subscription = Subscription.find_by(paddle_customer_id: data.customer_id)
          @user = @subscription&.user
        end

        @user
      end

      def process_event(event)
        PaddleEvent.create!(user: @user, payload: params)

        Rails.logger.info "Paddle #{event} for user #{@user.id}"

        method_name = event.gsub(".", "_")
        send(method_name) if respond_to?(method_name, true)
      end

      def subscription_created
        @subscription = @user.subscription || Subscription.create!(user: @user, plan: "annual")

        Rails.logger.info "New subscription #{@user.id} (subscription id: #{@subscription.id})"
        if @subscription.cancelled?
          Rails.logger.info "Subscription #{@subscription.id} was previously cancelled. Creating new subscription"

          # this is a re-activation of an existing subscription. delete and recreate
          @subscription.destroy!
          @subscription = Subscription.create!(user: @user, plan: "annual")
          Rails.logger.info "New subscription #{@subscription.id} created for @#{@user.id}"
        end

        @subscription.update!(
          paddle_subscription_id: data.id,
          paddle_customer_id: data.customer_id,
          paddle_price_id: data.items[0].price.id,
          unit_price: base_unit_price,
          next_billed_at: Time.parse(data.next_billed_at)
        )
      end

      def subscription_canceled
        Rails.logger.info "Subscription #{@subscription.id} cancelled"
        @subscription.update!(
          cancelled_at: Time.parse(data.canceled_at)
        )
      end

      def subscription_updated
        Rails.logger.info "Subscription #{@subscription.id} updated"

        next_billed_at = @subscription.next_billed_at
        if data.next_billed_at.present?
          next_billed_at = Time.parse(data.next_billed_at)
        end

        Rails.logger.info "Subscription next billed at updated to #{next_billed_at}"
        @subscription.update!(
          paddle_price_id: data.items[0].price.id,
          next_billed_at: next_billed_at
        )

        # this webhook is also called when a subscription is cancelled, with the
        # scheduled_change action set to cancel.
        if data.scheduled_change.present? &&
          if data.scheduled_change.action == "cancel"
            Rails.logger.info "Subscription is being cancelled"
            @subscription.update!(cancelled_at: Time.parse(data.scheduled_change.effective_at))
          end
        end
      end

      def subscription_past_due
        # No-op
        Rails.logger.info "Subscription past due"
      end

      def transaction_completed
        Rails.logger.info "Transaction completed. Updating next_billed_at and unit_price"

        return if data.origin == "subscription_payment_method_change"

        if data.custom_data&.lifetime
          handle_lifetime_purchase
          return
        end

        billing_period_ends_at = data.billing_period&.ends_at

        unless billing_period_ends_at
          Rails.logger.error "No next_billed_at in transaction_completed event"
          raise "No next_billed_at in transaction_completed event for #{@user.id} (#{@user.blog.subdomain})"
        end

        if @subscription.present?
          next_billed_at = Time.parse(billing_period_ends_at)
          actual_unit_price = transaction_unit_price

          @subscription.update!(
            next_billed_at: next_billed_at,
            unit_price: actual_unit_price
          )

          Rails.logger.info "Subscription #{@subscription.id} next billed on #{next_billed_at}, unit_price: #{actual_unit_price}"
        else
          raise "Subscription not found for transaction_completed event for #{@user.id} (#{@user.blog.subdomain})"
        end
      end

      def handle_lifetime_purchase
        Rails.logger.info "Lifetime purchase for user #{@user.id}"

        existing_paddle_subscription_id = @subscription&.paddle_subscription_id

        # Create or update subscription to lifetime plan
        subscription = @subscription || Subscription.create!(user: @user, plan: "lifetime")
        subscription.update!(
          plan: "lifetime",
          paddle_customer_id: data.customer_id,
          unit_price: transaction_unit_price,
          cancelled_at: nil
        )

        Rails.logger.info "Subscription #{subscription.id} upgraded to lifetime"

        # Cancel existing Paddle subscription if there was one
        if existing_paddle_subscription_id.present?
          Rails.logger.info "Cancelling existing Paddle subscription #{existing_paddle_subscription_id}"
          PaddleApi.new.cancel_subscription(existing_paddle_subscription_id, immediately: true)
        end
      end

      def transaction_payment_failed
        Rails.logger.warn "Payment failed for user #{@user.id} (#{@user.blog.subdomain}) - Paddle Retain will retry automatically"
      end

      def base_unit_price
        data.items[0].price.unit_price.amount.to_i
      end

      def transaction_unit_price
        data.details.line_items[0].unit_totals.total.to_i
      end

      def data
        @data ||= JSON.parse(params[:data].to_json, object_class: OpenStruct)
      end
  end
end
