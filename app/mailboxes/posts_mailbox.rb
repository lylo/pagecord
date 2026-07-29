class PostsMailbox < ApplicationMailbox
  def process
    return unless mail.to.present? && mail.from.present?

    recipient = ENV["PAGECORD_RECIPIENT"] || mail.to.first.downcase
    status = recipient.sub!(/\+draft@/, "@") ? :draft : :published
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
        parser = MailParser.new(mail, process_attachments: blog.user.has_premium_access?)
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
            status: status,
            source: :email,
            attachments: parser.attachments,
            tag_list: parser.tags,
            published_at: mail.date)
        end
      rescue ActiveRecord::RecordInvalid => e
        # Nothing a reader would see survived parsing. Retrying can't change
        # that, so report it once rather than raising for Sidekiq to try again
        # every few hours for three days.
        Rails.logger.error "Unable to create post from email: #{e.message}"
        report_to_sentry(e, blog, from)
      rescue => e
        Rails.logger.error "Unable to parse email: #{e}"
        raise "Unable to parse email: #{e}"
      end
    else
      Rails.logger.info "No blog found for from: #{from}, recipient: #{recipient}"
    end
  end

  private

    # Tags, not just context: Sentry aggregates tags on the issue page, so the
    # sender and blog are visible without opening an event and reading the job
    # arguments to find the inbound email.
    def report_to_sentry(error, blog, from)
      return unless Sentry.initialized?

      Sentry.set_tags(email_from: from, blog: blog.subdomain)
      Sentry.set_context("email", {
        from: from,
        subject: mail.subject,
        blog: blog.subdomain,
        inbound_email_id: inbound_email.id
      })
      Sentry.capture_exception(error)
    end

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
