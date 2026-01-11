class SpamDetectionDigestJob < ApplicationJob
  queue_as :default

  def perform
    detections = SpamDetection.needs_review.today.includes(blog: :user)

    return if detections.empty?

    Rails.logger.info "[SpamDetection] Sending digest with #{detections.count} detections"
    AdminMailer.spam_detection_digest(detections.pluck(:id)).deliver_later
  end
end
