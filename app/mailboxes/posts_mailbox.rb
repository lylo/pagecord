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

    if spf_present?(mail) && !spf_passed?(mail)
      Rails.logger.warn "SPF failed" and return
    end

    if user = User.kept.find_by(email: from, delivery_email: recipient)
      begin
        parser = MailParser.new(mail)
        unless parser.is_blank?
          content = parser.body
          title = parser.subject

          if parser.body_blank?
            content = title
            title = nil
          end

          attachments = if user.subscribed?
            parser.attachments
          else
            []
          end

          Rails.logger.info "Creating post from user: #{user.id}"
          user.posts.create!(
            title: title,
            content: content,
            raw_content: mail.raw_source,
            attachments: attachments,
            published_at: mail.date)
        end
      rescue => e
        Rails.logger.error "Unable to parse email: #{e}"
        raise "Unable to parse email: #{e}"
      end
    else
      raise "User not found. From: #{from}, To: #{recipient}"
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
