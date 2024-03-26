class MailParser
  include ActionView::Helpers::SanitizeHelper

  def initialize(mail)
    @mail = mail
    @pipeline = [
      Html::BodyExtraction.new,
      Html::MonospaceDetection.new,
      Html::ImageUnfurl.new,
      Html::Utf8Encoding.new,
      Html::Sanitize.new,
    ]
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

  def is_blank?
    subject.blank? && strip_tags(body)&.strip.blank?
  end

  private

    def parse_body
      if @mail.multipart?
        if @mail.html_part
          html = @mail.html_part.decoded
          @pipeline.each do |transformation|
            html = transformation.transform(html)
          end
          html
        elsif @mail.text_part
          @mail.text_part.body.decoded
        end
      elsif @mail.content_type =~ /text\/plain/
        @mail.decoded
      else
        raise "Unknown content type #{mail.content_type}"
      end
    end
end
