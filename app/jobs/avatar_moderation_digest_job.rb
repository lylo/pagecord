class AvatarModerationDigestJob < ApplicationJob
  queue_as :default

  def perform
    count = AvatarModeration.needs_review
                            .joins(blog: :user)
                            .where(users: { discarded_at: nil })
                            .count

    return if count.zero?

    Rails.logger.info "[AvatarModeration] Sending digest: #{count} avatars need review"
    AdminMailer.avatar_moderation_digest(count).deliver_later
  end
end
