class CancelPaddleSubscriptionJob < ApplicationJob
  queue_as :default

  def perform(paddle_subscription_id)
    PaddleApi.new.cancel_subscription(paddle_subscription_id)
  end
end
