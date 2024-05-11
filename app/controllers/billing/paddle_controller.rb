module Billing
  class PaddleController < AppController
    # POST /billing/paddle/create_update_payment_method_transaction
    #
    # Create a new transaction as required by Paddle to update the payment method
    # for the subscription
    #
    # See https://developer.paddle.com/build/subscriptions/update-payment-details
    def create_update_payment_method_transaction
      response = PaddleApi.new.get_update_payment_method_transaction(subscription.paddle_subscription_id)

      render json: { transaction_id: response["data"]["id"] }
    end

    private

      def subscription
        @subscription ||= Current.user.subscription
      end
  end
end
