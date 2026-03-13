class ContentModerationDigestJob < ApplicationJob
  queue_as :default

  def perform
    count = Post.kept.moderation_flagged.published.joins(blog: :user).where(users: { discarded_at: nil }).count

    return if count.zero?

    Rails.logger.info "[ContentModeration] Sending digest: #{count} posts need review"
    AdminMailer.content_moderation_digest(count).deliver_later
  end
end
