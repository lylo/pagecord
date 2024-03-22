class PostsMailbox < ApplicationMailbox
  include ActionView::Helpers::SanitizeHelper

  def process
    recipient = mail.to.first.downcase
    from = mail.from.first.downcase

    Rails.logger.info "Received mail from: #{from} to: #{recipient}"

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

      # if there is no content, use the title as content and blank out the title.
      # adds twitter like functionality.
      if content_blank
        content = title
        title = nil
      end

      user.posts.create!(title: title, content: content, html: parser.html?, published_at: mail.date)
    end
  end
end
