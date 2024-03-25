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
      html = decode(@mail.html_part.decoded)
      body = extract_body_tag(html)
      sanitize(body)
    elsif @mail.multipart? && @mail.text_part
      @mail.text_part.body.decoded
    else
      @mail.decoded
    end
  end

  private

    def decode(html)
      html_decoder = HTMLEntities.new
      decoded_body = html_decoder.decode(html).force_encoding('UTF-8')
    end

    def extract_body_tag(html)
      document = Nokogiri::HTML(html)
      body = document.at_css("body").inner_html
    end

    ALLOWED_TAGS =  %w(a abbr b blockquote br cite code del div em h1 h2 h3 h4 h5 h6 hr i li mark ol p pre s span strike strong u ul)
    ALLOWED_ATTRIBUTES = %w(href class)

    def sanitize(html)
      sanitizer = Rails::HTML5::SafeListSanitizer.new
      sanitizer.sanitize html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES
    end
end
