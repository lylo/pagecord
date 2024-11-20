class MailParser
  include ActionView::Helpers::SanitizeHelper

  def initialize(mail)
    @mail = mail
    @attachment_transformer = Html::MailAttachments.new(mail)

    @html_pipeline = [
        Html::BodyExtraction.new,
        Html::MonospaceDetection.new,
        Html::ImageUnfurl.new,
        @attachment_transformer,
        Html::Sanitize.new
      ]
    @plain_text_pipeline = [
        Html::PlainTextToHtml.new,
        @attachment_transformer
      ]
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
        if @mail.html_part
          html_transform(@mail.html_part.decoded)
        elsif @mail.text_part
          plain_text_transform(@mail.text_part.decoded)
        end
      elsif @mail.content_type =~ /text\/plain/
        plain_text_transform(@mail.decoded)
      else
        raise "Unknown content type #{@mail.content_type}"
      end
    end


    def sanitized_body
      @sanitized_body ||= sanitize(body, tags: %w[img], attributes: %w[src alt])
    end
end
