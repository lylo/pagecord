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

        user.transaction do
          user.create_unengaged_follow_up!(sent_at: Time.current)
          WelcomeMailer.with(user: user).unengaged_follow_up.deliver_later(wait: i.seconds)
        end
      end
    end
  end
end
