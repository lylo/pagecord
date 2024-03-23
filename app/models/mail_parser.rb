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
      decoded_body = CGI.unescapeHTML(@mail.html_part.body.decoded)
      document = Nokogiri::HTML(decoded_body)
      body = document.at_css("body").inner_html.force_encoding("UTF-8").encode("UTF-8")

      sanitizer = Rails::HTML5::SafeListSanitizer.new
      sanitizer.sanitize(body, tags: %w(a abbr b blockquote br cite code div em h1 h2 h3 h4 h5 h6 hr i li mark ol p pre strong u ul), attributes: %w(href))
    elsif @mail.multipart? && @mail.text_part
      @mail.text_part.body.decoded
    else
      @mail.decoded
    end
  end
end
