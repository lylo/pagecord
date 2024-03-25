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
      body = extract_body_tag(process_html(html))
      sanitize(body).strip
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
      document.at_css("body").inner_html
    end

    def process_html(html)
      process_monospace(html)
    end

    def process_monospace(html)
      document = Nokogiri::HTML(html)

      replace_style_tags_with_code_tags(document)
      replace_font_tags_with_code_tags(document)

      document.to_html
    end

    # Fastmail wraps monospace lines in <span style="font-family: monospace"> tags
    def replace_style_tags_with_code_tags(document)
      document.css("div[style], span[style]").each do |element|
        if element['style'].downcase.include?('font-family: monospace')
          code = Nokogiri::XML::Node.new "code", document
          code.children = element.children
          element.replace code
        end
      end
    end

    # Gmail wraps monospace in <font face="monospace"> tags
    def replace_font_tags_with_code_tags(document)
      document.css("font[face]").each do |element|
        if element["face"].downcase == "monospace"
          tag = Nokogiri::XML::Node.new "code", document
          tag.inner_html = element.inner_html
          element.replace tag    # replace <font> tag with <code>
        end
      end
    end

    ALLOWED_TAGS =  %w(a abbr b blockquote br cite code del div em h1 h2 h3 h4 h5 h6 hr i li mark ol p pre s span strike strong u ul)
    ALLOWED_ATTRIBUTES = %w(href)

    def sanitize(html)
      sanitizer = Rails::HTML5::SafeListSanitizer.new
      sanitizer.sanitize html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES
    end
end
