class SendTrialEndedEmailsJob < ApplicationJob
  queue_as :default

  def perform
    users = User.where(trial_ends_at: Date.yesterday)
                .where(discarded_at: nil)
                .left_joins(:subscription)
                .where(subscriptions: { id: nil })

    Rails.logger.info "[SendTrialEndedEmails] Sending trial ended emails to #{users.count} users"

    users.find_each do |user|
      FreeTrialMailer.with(user: user).trial_ended.deliver_later
    end
  end
end
