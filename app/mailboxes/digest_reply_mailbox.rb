class DigestReplyMailbox < ApplicationMailbox
  def process
    return unless mail.to.present? && mail.from.present?

    # Extract masked digest ID from email address (digest-reply-abc123@post.pagecord.com)
    recipient = mail.to.first.downcase
    masked_id = recipient.match(/digest-reply-([^@]+)@/i)&.captures&.first

    return unless masked_id

    digest = PostDigest.find_by_masked_id(masked_id)
    return unless digest

    # Only forward if the sender is a subscriber to this blog
    from_email = mail.from.first.downcase
    return unless digest.blog.email_subscribers.confirmed.exists?(email: from_email)

    # Forward the email to the blog owner
    DigestReplyMailer.forward_reply(
      digest: digest,
      original_mail: mail
    ).deliver_now

  rescue => e
    Rails.logger.error "Unable to process digest reply: #{e}"
    Sentry.capture_exception(e, extra: {
      from: mail.from&.first,
      to: mail.to&.first,
      masked_id: masked_id
    })
  end
end