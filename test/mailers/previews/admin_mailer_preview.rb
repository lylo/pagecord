class AdminMailerPreview < ActionMailer::Preview
  def spam_detected_notification
    user = User.joins(:blog).first || User.create!(email: "preview@example.com", password: "password", blog_attributes: { subdomain: "preview-blog", title: "Preview Blog" })
    classification = "spam"
    reason = "The blog contains multiple backlinks to known gambling sites and generates nonsensical SEO content."

    AdminMailer.spam_detected_notification(user.id, classification, reason)
  end
end
