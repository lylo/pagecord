class MailParser

  def initialize(mail)
    @mail = mail
  end

  def html?
    @mail.multipart? && @mail.html_part
  end

  def plain_text?
    !html?
  end

  def body
    if html?
      html_decoder = HTMLEntities.new
      decoded_body = html_decoder.decode(@mail.html_part.decoded).force_encoding('UTF-8')
      document = Nokogiri::HTML(decoded_body)
      body = document.at_css("body").inner_html

      sanitizer = Rails::HTML5::SafeListSanitizer.new
      sanitizer.sanitize(body, tags: %w(a abbr b blockquote br cite code del div em h1 h2 h3 h4 h5 h6 hr i li mark ol p pre s strike strong u ul), attributes: %w(href))
    elsif @mail.multipart? && @mail.text_part
      @mail.text_part.body.decoded
    else
      @mail.decoded
    end
  end
end
