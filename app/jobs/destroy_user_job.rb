class DestroyUserJob < ApplicationJob
  queue_as :default

  def perform(user_id, options = {})
    user = User.find(user_id)
    user.discard!

    if user.subscription
      PaddleApi.new.cancel_subscription(user.subscription.paddle_subscription_id)
    end

    MarketingAutomation::DeleteContactJob.perform_later(user_id) if options[:spam]
  end
end
