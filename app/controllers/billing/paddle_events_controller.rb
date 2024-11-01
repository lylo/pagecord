require "openssl"
require "ostruct"

module Billing
  class PaddleEventsController < ApplicationController
    skip_before_action :verify_authenticity_token, :authenticate, :domain_check

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
        elsif data.customer_id
          @subscription = Subscription.find_by(paddle_customer_id: data.customer_id)
          @user = @subscription&.user
        end
      end

      def process_event(event)
        PaddleEvent.create!(user: @user, payload: params)

        @subscription = @user.subscription || Subscription.create!(user: @user)

        Rails.logger.info "Paddle #{event} for @#{@user.username}"

        method_name = event.gsub(".", "_")
        send(method_name) if respond_to?(method_name, true)
      end

      def subscription_created
        Rails.logger.info "Subscription #{@subscription.id} created"
        if @subscription.cancelled?
          Rails.logger.info "Subscription #{@subscription.id} was previously cancelled. Creating new subscription"

          # this is a re-activation of an existing subscription. delete and recreate
          @subscription.destroy!
          @subscription = Subscription.create!(user: @user)
          Rails.logger.info "New subscription #{@subscription.id} created for @#{@user.username}"
        end

        @subscription.update!(
          paddle_subscription_id: data.id,
          paddle_customer_id: data.customer_id,
          paddle_price_id: data.items[0].price.id,
          unit_price: data.items[0].price.unit_price.amount.to_i,
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
            unit_price: data.items[0].price.unit_price.amount.to_i,
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
        # No-op
        Rails.logger.info "Transaction completed"
      end

      def transaction_payment_failed
        # No-op
        Rails.logger.info "Transaction payment failed"
      end

      def data
        @data ||= JSON.parse(params[:data].to_json, object_class: OpenStruct)
      end
  end
end
