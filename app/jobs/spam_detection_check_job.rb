class SpamDetectionCheckJob < ApplicationJob
  queue_as :default

  def perform(blog_id)
    blog = Blog.find_by(id: blog_id)
    return unless blog

    detector = SpamDetector.new(blog)
    detector.detect

    Rails.logger.info "[SpamDetection] #{blog.subdomain}: #{detector.classification} - #{detector.reason}"

    return if detector.not_spam?

    AdminMailer.spam_detected_notification(blog.user.id, detector.classification, detector.reason).deliver_later
  end
end
