class PostsMailbox < ApplicationMailbox
  def process
    return unless mail.to.present? && mail.from.present?

    recipient = ENV["PAGECORD_RECIPIENT"] || mail.to.first.downcase
    from = ENV["PAGECORD_FROM"] || mail.from.first.downcase

    reply_to = if ENV["PAGECORD_REPLYTO"]
      ENV["PAGECORD_REPLYTO"]
    else
      mail.reply_to&.first&.downcase
    end

    if reply_to.present? && reply_to != from
      Rails.logger.warn "Reply-To and From are inconsistent" and return
    end

    if blog = Blog.joins(:user).find_by(user: { email: from }, delivery_email: recipient)
      # if user = User.kept.find_by(email: from, delivery_email: recipient)
      begin
        parser = MailParser.new(mail, process_attachments: blog.user.subscribed?)
        unless parser.is_blank?
          content = parser.body
          title = parser.subject

          if parser.body_blank?
            content = title
            title = nil
          end

          Rails.logger.info "Creating post from user: #{blog.user.id}"
          blog.user.blog.posts.create!(
            blog: blog,
            title: title,
            content: content,
            raw_content: mail.raw_source,
            attachments: parser.attachments,
            published_at: mail.date)
        end
      rescue => e
        Rails.logger.error "Unable to parse email: #{e}"
        raise "Unable to parse email: #{e}"
      end
    else
      # Raise an error in Sentry for information. No need to retry the email
      Sentry.capture_message("User not found. From: #{from}, To: #{recipient}")
    end
  end
end
