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

  def content_flagged_notification(post_id)
    @post = Post.find(post_id)
    @blog = @post.blog

    mail(
      to: "hello@pagecord.com",
      subject: "Content Flagged: #{@blog.subdomain} - #{@post.display_title.truncate(50)}"
    )
  end
end
