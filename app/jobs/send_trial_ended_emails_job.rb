class SendTrialEndedEmailsJob < ApplicationJob
  queue_as :default

  def perform
    trial_ended_date = Subscribable::TRIAL_PERIOD_DAYS.days.ago.to_date

    users = User.where(created_at: trial_ended_date.all_day)
                .where(discarded_at: nil)
                .left_joins(:subscription)
                .where(subscriptions: { id: nil })

    Rails.logger.info "[SendTrialEndedEmails] Sending trial ended emails to #{users.count} users"

    users.find_each do |user|
      FreeTrialMailer.with(user: user).trial_ended.deliver_later
    end
  end
end
