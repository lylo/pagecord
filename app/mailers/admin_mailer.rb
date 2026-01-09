class AdminMailer < ApplicationMailer
  def spam_detection_digest(detection_ids)
    @detections = SpamDetection.where(id: detection_ids)
                               .includes(blog: :user)
                               .order(status: :desc, detected_at: :desc)

    @spam_count = @detections.spam.count
    @uncertain_count = @detections.uncertain.count

    mail(
      to: "hello@pagecord.com",
      subject: "Spam Detection Digest: #{@detections.count} blogs flagged"
    )
  end

  def content_moderation_digest(count)
    @count = count

    mail(
      to: "hello@pagecord.com",
      subject: "Content Moderation: #{@count} posts need review"
    )
  end
end
