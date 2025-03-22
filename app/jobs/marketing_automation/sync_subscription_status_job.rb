require "loops_sdk"

class MarketingAutomation::SyncSubscriptionStatusJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    return unless Rails.env.production?

    user = User.find(user_id)
    return unless user

    update_subscription_status(user)
  end

  private

    def update_subscription_status(user)
      status = user.subscribed? ? "premium" : "free"

      LoopsSdk::Contacts.update(
        email: user.email,
        properties: {
          status: status
        }
      )
    rescue LoopsSdk::APIError => e
      Rails.logger.error("Failed to update subscription status for user #{user.id}: #{e.message}")
      raise e
    end
end
