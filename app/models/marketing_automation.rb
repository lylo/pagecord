class MarketingAutomation
  def self.send_getting_started_emails
    users = User.kept.where(created_at: 2.days.ago..1.day.ago)
    users.find_each do |user|
      MarketingAutomation::GettingStartedEmailJob.perform_later(user.id)
    end
  end

  def self.sync_subscription_statuses
    User.kept.find_each do |user|
      # spread out the requests to avoid Loops rate limits
      random_delay = rand(10.minutes)

      MarketingAutomation::SyncSubscriptionStatusJob
        .set(wait: random_delay)
        .perform_later(user.id)
    end
  end
end
