class SendTrialEndedEmailsJob < ApplicationJob
  queue_as :default

  def perform
    users = User.kept
                .includes(:blog)
                .where(verified: true)
                .where(trial_ends_at: Date.yesterday)
                .where.missing(:subscription)

    Rails.logger.info "[SendTrialEndedEmails] Sending trial ended emails to #{users.count} users"

    users.find_each do |user|
      with_sentry_context(user: user, blog: user.blog) do
        FreeTrialMailer.with(user: user).trial_ended.deliver_later
      end
    end
  end
end
