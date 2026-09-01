class DestroyUserJob < ApplicationJob
  queue_as :default

  def perform(user_id, reason: :user_deleted)
    user = User.find(user_id)
    with_sentry_context(user: user, blog: user.blog) do
      ActiveRecord::Base.transaction do
        user.discard!
        AccountTombstone.record!(user, reason: reason)
      end

      user.blogs.find_each(&:touch)

      if user.subscription
        PaddleApi.new.cancel_subscription(user.subscription.paddle_subscription_id)
      end

      MarketingAutomation::DeleteContactJob.perform_later(user_id) if reason.to_s == "spam"
    end
  end
end
