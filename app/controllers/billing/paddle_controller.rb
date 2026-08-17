module Billing
  class PaddleController < AppController
    # POST /billing/paddle/create_update_payment_method_transaction
    #
    # Create a new transaction as required by Paddle to update the payment method
    # for the subscription
    #
    # See https://developer.paddle.com/build/subscriptions/update-payment-details
    def create_update_payment_method_transaction
      return head :not_found if subscription.blank?

      response = PaddleApi.new.get_update_payment_method_transaction(subscription.paddle_subscription_id)
      transaction_id = response.dig("data", "id")

      if transaction_id.present?
        render json: { transaction_id: transaction_id }
      else
        # Paddle refuses this for subscriptions it has already cancelled, so a
        # failure here is expected rather than exceptional.
        Rails.logger.error "No payment method update transaction for user #{Current.user.id} (#{subscription.paddle_subscription_id}): #{response["error"]}"
        head :unprocessable_content
      end
    end

    private

      def subscription
        @subscription ||= Current.user.subscription
      end
  end
end
