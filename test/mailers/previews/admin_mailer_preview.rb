class AdminMailerPreview < ActionMailer::Preview
  def spam_detection_digest
    detections = SpamDetection.where(status: [:spam, :uncertain]).limit(5)

    if detections.empty?
      # Create preview data if none exists
      blog = Blog.first
      detection_ids = [
        SpamDetection.create!(
          blog: blog,
          status: :spam,
          reason: "Multiple commercial links detected in bio and posts. Keyword stuffing in subdomain.",
          detected_at: 2.hours.ago
        ).id,
        SpamDetection.create!(
          blog: blog,
          status: :uncertain,
          reason: "Mixed signals - contains health-related content with some external links.",
          detected_at: 1.hour.ago
        ).id
      ]
    else
      detection_ids = detections.pluck(:id)
    end

    AdminMailer.spam_detection_digest(detection_ids)
  end

  def content_flagged_notification
    post = Post.published.first
    AdminMailer.content_flagged_notification(post.id)
  end
end
