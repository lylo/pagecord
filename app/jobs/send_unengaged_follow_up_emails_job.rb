class SendUnengagedFollowUpEmailsJob < ApplicationJob
  queue_as :default

  def perform
    users = User.kept
                .includes(:blog)
                .where(verified: true)
                .where(created_at: ..1.month.ago)
                .where.missing(:subscription, :unengaged_follow_up)

    Rails.logger.info "[SendUnengagedFollowUpEmails] Checking #{users.count} users"

    users.find_each.with_index do |user, i|
      with_sentry_context(user: user, blog: user.blog) do
        next if user.blog.all_posts.exists?

        if user.onboarding_state == "account_created"
          send_follow_up(user, :onboarding_follow_up, i)
        else
          send_follow_up(user, :no_content_follow_up, i)
        end
      end
    end
  end

  private

    def send_follow_up(user, mailer_action, delay)
      user.transaction do
        user.create_unengaged_follow_up!(sent_at: Time.current)
        WelcomeMailer.with(user: user).public_send(mailer_action).deliver_later(wait: delay.seconds)
      end
    end
end
