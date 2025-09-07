module Html
  class Sanitize < Transformation
    ALLOWED_TAGS = %w[
      a abbr figure figcaption action-text-attachment b blockquote br cite code del div em h1 h2 h3 h4 h5 h6 hr i img li mark ol p pre s span strike strong u ul
    ]
    ALLOWED_ATTRIBUTES = %w[
      href src sgid url content-type name filename previewable filesize class alt
    ]

    def transform(html)
      document = Nokogiri::HTML::DocumentFragment.parse(html)
      document.search("img").each do |img|
        # Preserve images inside ActionText attachments
        if img.ancestors("action-text-attachment").any?
          # Keep ActionText attachment images
        elsif img["pagecord"] == "true"
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
