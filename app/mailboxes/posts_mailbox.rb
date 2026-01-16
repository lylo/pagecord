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

    if blog = blog_from_email(from, recipient)
      begin
        parser = MailParser.new(mail, process_attachments: blog.user.subscribed? || blog.user.on_trial?)
        unless parser.blank?
          content = parser.body
          title = parser.subject

          if parser.body_blank?
            content = title
            title = nil
          end

          Rails.logger.info "Creating post from user: #{blog.user.id}"
          blog.posts.create!(
            title: title,
            content: content,
            raw_content: mail.raw_source,
            attachments: parser.attachments,
            tag_list: parser.tags,
            published_at: mail.date)
        end
      rescue => e
        Rails.logger.error "Unable to parse email: #{e}"
        raise "Unable to parse email: #{e}"
      end
    else
      # Raise an error in Sentry for information. No need to retry the email
      Sentry.with_scope do |scope|
        scope.set_tags(from: from, recipient: recipient)
        Sentry.capture_message("User not found")
      end

      Appsignal.report_error(StandardError.new("User not found")) do |transaction|
        Appsignal.set_action("PostsMailbox#process")
        Appsignal.add_tags(
          from: from,
          recipient: recipient
        )
      end
    end
  end

  private

    def blog_from_email(from_email, delivery_email)
      find_blog_by_user_email(from_email, delivery_email) ||
      find_blog_by_verified_sender_email(from_email, delivery_email)
    end

    def find_blog_by_user_email(from_email, delivery_email)
      Blog.joins(:user).find_by(user: { email: from_email }, delivery_email: delivery_email)
    end

    def find_blog_by_verified_sender_email(from_email, delivery_email)
      Blog.joins(:sender_email_addresses)
          .where(delivery_email: delivery_email)
          .where(sender_email_addresses: { email: from_email })
          .where.not(sender_email_addresses: { accepted_at: nil })
          .first
    end
end
