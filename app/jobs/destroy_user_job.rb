class DestroyUserJob < ApplicationJob
  queue_as :default

  def perform(user_id, options = {})
    user = User.find(user_id)
    user.discard!

    if user.subscription
      PaddleApi.new.cancel_subscription(user.subscription.paddle_subscription_id)
    end

    if options[:spam]
      create_spam_detection(user.blog)
      MarketingAutomation::DeleteContactJob.perform_later(user_id)
    end
  end

  private

    def create_spam_detection(blog)
      detection = blog.spam_detection || blog.build_spam_detection
      detection.update!(
        status: :spam,
        reason: "Manually marked as spam by admin",
        detected_at: Time.current,
        reviewed_at: Time.current
      )
    end
end
