class SendUnengagedFollowUpEmailsJob < ApplicationJob
  queue_as :default

  def perform
    users = User.kept
                .where(created_at: ..1.month.ago)
                .where.missing(:subscription)

    Rails.logger.info "[SendUnengagedFollowUpEmails] Checking #{users.count} users"

    users.find_each.with_index do |user, i|
      next if user.unengaged_follow_up.present?
      next if user.blog.all_posts.exists?

      user.transaction do
        user.create_unengaged_follow_up!(sent_at: Time.current)
        WelcomeMailer.with(user: user).unengaged_follow_up.deliver_later(wait: i.seconds)
      end
    end
  end
end
