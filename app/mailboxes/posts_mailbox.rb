class PostsMailbox < ApplicationMailbox
  include ActionView::Helpers::SanitizeHelper

  def process
    return unless mail.to.present? && mail.from.present?

    recipient = mail.to.first.downcase
    from = mail.from.first.downcase
    reply_to = mail.reply_to.first.downcase if mail.reply_to.present?
    Rails.logger.info "Received mail from: #{from} to: #{recipient} (reply-to: #{reply_to})"

    if reply_to.present? && reply_to != from
      Rails.logger.warn "Reply-To and From are inconsistent" and return
    end

    if spf_present?(mail) && !spf_passed?(mail)
      Rails.logger.warn "SPF failed" and return
    end

    if user = User.find_by(email: from, delivery_email: recipient)
      Rails.logger.info "Creating post from user: #{user.id}"

      parser = MailParser.new(mail)
      title = mail.subject&.strip
      content = parser.body

      content_blank = if parser.html?
        strip_tags(content)&.strip.blank?
      else
        content&.strip.blank?
      end

      return if content_blank && title.blank?

      user.posts.create!(title: title, content: content, html: parser.html?, published_at: mail.date)
    end
  end

  def spf_present?(mail)
    mail.header_fields.any? { |field| field.name == "Received-SPF" }
  end

  def spf_passed?(mail)
    mail.header_fields.any? { |field| field.name == "Received-SPF" && field.value.include?("pass") }
  end

  def dkim_passed?(mail)
    mail.header_fields.any? { |field| field.name == "DKIM-Signature" }
  end
end
