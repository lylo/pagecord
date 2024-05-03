class MailParser
  include ActionView::Helpers::SanitizeHelper

  def initialize(mail, process_attachments: false)
    @mail = mail
    @pipeline = if process_attachments
      [
        Html::BodyExtraction.new,
        Html::MonospaceDetection.new,
        Html::ImageUnfurl.new,
        @attachment_transformer = Html::MailAttachments.new(mail),
        Html::Utf8Encoding.new,
        Html::Sanitize.new,
      ]
    else
      [
        Html::BodyExtraction.new,
        Html::MonospaceDetection.new,
        Html::ImageUnfurl.new,
        Html::Utf8Encoding.new,
        Html::Sanitize.new,
      ]
    end
  end

  def subject
    @title ||= @mail.subject&.strip
  end

  def body
    @body ||= parse_body
  end

  def html?
    @mail.multipart? && @mail.html_part
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

  def transform(html)
    @pipeline.each do |transformation|
      html = transformation.transform(html)
    end
    html
  end

  private

    def parse_body
      if @mail.multipart?
        if @mail.html_part
          transform @mail.html_part.decoded
        elsif @mail.text_part
          @mail.text_part.body.decoded
        end
      elsif @mail.content_type =~ /text\/plain/
        @mail.decoded
      else
        raise "Unknown content type #{mail.content_type}"
      end
    end

    def sanitized_body
      @sanitized_body ||= sanitize(body, tags: %w(img), attributes: %w(src alt))
    end
end
