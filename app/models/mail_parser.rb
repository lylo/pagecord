class MailParser

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

  def html?
    @mail.multipart? && @mail.html_part
  end

  def plain_text?
    !html?
  end

  def body
    if html?
      html = @mail.html_part.decoded
      @pipeline.each do |transformation|
        html = transformation.transform(html)
      end
      html
    elsif @mail.multipart? && @mail.text_part
      @mail.text_part.body.decoded
    elsif @mail.content_type =~ /text\/plain/
      @mail.decoded
    else
      Rails.logger.warn "Unable to parse email content type: #{@mail.content_type}"
      nil
    end
  end
end
