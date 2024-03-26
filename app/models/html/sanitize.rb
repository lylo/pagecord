module Html
  class Sanitize < Transformation
    ALLOWED_TAGS =  %w(a abbr b blockquote br cite code del div em h1 h2 h3 h4 h5 h6 hr i img li mark ol p pre s span strike strong u ul)
    ALLOWED_ATTRIBUTES = %w(href)

    def transform(html)
      document = Nokogiri::HTML::DocumentFragment.parse(html)
      document.search("img").each do |img|
        if img["pagecord"] == "true"
          img.remove_attribute("pagecord")
        else
          img.remove
        end
      end

      sanitizer = Rails::HTML5::SafeListSanitizer.new
      sanitizer.sanitize(document.to_html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES).strip
    end
  end
end