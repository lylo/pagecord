module Admin::ModerationHelper
  def content_moderation_count
    @content_moderation_count ||= Post.with_discarded
                                      .moderation_flagged
                                      .published
                                      .joins(blog: :user)
                                      .where(users: { discarded_at: nil })
                                      .count
  end

  def spam_detection_count
    @spam_detection_count ||= SpamDetection.needs_review.count
  end
end
