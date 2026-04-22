class SendTrialReminderEmailsJob < ApplicationJob
  queue_as :default

  def perform
    users = User.kept
                .includes(:blog)
                .where(verified: true)
                .where(trial_ends_at: 3.days.from_now.to_date)
                .where.missing(:subscription)

    Rails.logger.info "[SendTrialReminderEmails] Sending trial reminder emails to #{users.count} users"

    users.find_each do |user|
      with_sentry_context(user: user, blog: user.blog) do
        FreeTrialMailer.with(user: user).trial_reminder.deliver_later
      end
    end
  end
end
