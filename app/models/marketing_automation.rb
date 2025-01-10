class MarketingAutomation
  def self.send_getting_started_emails
    users = User.where(created_at: 2.days.ago..1.day.ago).where(marketing_consent: true)
    users.find_each do |user|
      MarketingAutomation::GettingStartedEmailJob.perform_later(user.id)
    end
  end
end
