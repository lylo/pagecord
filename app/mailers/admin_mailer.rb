class AdminMailer < CloudflareMailer
  def blog_review_digest(count)
    @count = count

    mail(
      to: "hello@pagecord.com",
      subject: "Blog review: #{@count} #{"blog".pluralize(@count)} waiting"
    )
  end

  def content_moderation_digest(count)
    @count = count

    mail(
      to: "hello@pagecord.com",
      subject: "Content Moderation: #{@count} posts need review"
    )
  end

  def deliverability_digest(count)
    @count = count

    mail(
      to: "hello@pagecord.com",
      subject: "Deliverability: #{@count} #{"address".pluralize(@count)} to review"
    )
  end
end
