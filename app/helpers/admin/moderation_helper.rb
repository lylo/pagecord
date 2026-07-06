module Admin::ModerationHelper
  def content_moderation_count
    @content_moderation_count ||= Post.kept
                                      .moderation_flagged
                                      .published
                                      .joins(blog: :user)
                                      .where(users: { discarded_at: nil })
                                      .count
  end

  def spam_detection_count
    @spam_detection_count ||= SpamDetection.needs_review.count
  end

  def avatar_moderation_count
    @avatar_moderation_count ||= AvatarModeration.needs_review
                                                 .joins(blog: :user)
                                                 .where(users: { discarded_at: nil })
                                                 .count
  end
end
