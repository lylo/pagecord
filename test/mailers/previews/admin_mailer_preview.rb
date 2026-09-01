class AdminMailerPreview < ActionMailer::Preview
  def blog_review_digest
    AdminMailer.blog_review_digest(3)
  end

  def content_moderation_digest
    AdminMailer.content_moderation_digest(5)
  end

  def deliverability_digest
    AdminMailer.deliverability_digest(5)
  end
end
