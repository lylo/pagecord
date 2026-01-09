class SpamDetectionCheckJob < ApplicationJob
  queue_as :default

  def perform(blog_id)
    blog = Blog.find_by(id: blog_id)
    return unless blog

    detector = SpamDetector.new(blog)
    detector.detect

    Rails.logger.info "[SpamDetection] #{blog.subdomain}: #{detector.result.status} - #{detector.result.reason}"

    save_detection_result!(blog, detector.result)
  end

  private

    def save_detection_result!(blog, result)
      detection = blog.spam_detection || blog.build_spam_detection
      detection.update!(
        status: result.status,
        reason: result.reason,
        detected_at: Time.current,
        model_version: result.model_version,
        reviewed_at: nil
      )
    end
end
