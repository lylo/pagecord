class MailParser
  include ActionView::Helpers::SanitizeHelper

  def initialize(mail, process_attachments: true)
    @mail = mail

    @html_pipeline = [
      Html::BodyExtraction.new,
      Html::MonospaceDetection.new,
      Html::ImageUnfurl.new,
      Html::Sanitize.new
    ]

    @plain_text_pipeline = [
      Html::PlainTextToHtml.new,
      Html::ImageUnfurl.new
    ]

    if process_attachments
      @attachment_transformer = Html::MailAttachments.new(mail)

      @html_pipeline.insert(-2, @attachment_transformer)  # append before Html::Sanitize
      @plain_text_pipeline << @attachment_transformer
    end
  end

  def subject
    @title ||= @mail.subject&.strip
  end

  def body
    @body ||= parse_body
  end

  def attachments
    @attachment_transformer&.attachments || []
  end

  def has_attachments?
    !attachments.empty?
  end

  def is_blank?
    subject_blank? && body_blank?
  end

  def subject_blank?
    subject.blank?
  end

  def body_blank?
    sanitized_body.strip.blank? && !has_attachments?
  end

  private

    def html_transform(html)
      transform(@html_pipeline, html)
    end

    def plain_text_transform(html)
      transform(@plain_text_pipeline, html)
    end

    def transform(pipeline, html)
      charset = @mail.charset || "UTF-8"
      if charset.downcase != "utf-8"
        Rails.logger.info "Converting mail from #{charset} to UTF-8"
        decoded = html.encode(charset, "UTF-8", invalid: :replace, undef: :replace, replace: "")
        html = decoded.force_encoding("UTF-8")
      end

      pipeline.each do |transformation|
        html = transformation.transform(html)
      end
      html
    end

    def parse_body
      if @mail.multipart?
        flattened_parts = flatten_parts(@mail)
        html_parts = flattened_parts.select { |part| part.content_type.start_with?("text/html") }
        text_parts = flattened_parts.select { |part| part.content_type.start_with?("text/plain") }

        if html_parts.any?
          html_content = html_parts.map(&:decoded).join("\n")
          html_transform(html_content)
        elsif text_parts.any?
          text_content = text_parts.map(&:decoded).join("\n")
          plain_text_transform(text_content)
        end
      else
        case @mail.content_type
        when /text\/plain/
          plain_text_transform(@mail.decoded)
        when /text\/html/
          html_transform(@mail.decoded)
        else
          raise "Unknown content type #{@mail.content_type}"
        end
      end
    end

    def flatten_parts(mail_part)
      parts = []

      mail_part.parts.each do |part|
        if part.multipart?
          parts.concat(flatten_parts(part))
        else
          parts << part
        end
      end

      parts
    end

    def sanitized_body
      @sanitized_body ||= sanitize(body, tags: %w[img], attributes: %w[src alt])
    end
end
