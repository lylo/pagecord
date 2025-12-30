require "fastimage"

module Html
  class ImageUnfurl < Transformation
    def transform(html)
      document = Nokogiri::HTML.fragment(html)

      document.traverse do |node|
        href = node["href"]

        if node.text? && node.parent&.name != "a"
          URI.extract(node.content, [ "http", "https" ]).each do |url|
            if valid_image?(url)
              replace_url_with_image(document, node, url)
            end
          end
        elsif node.name == "a" && href.present? && node.content.include?(href) && valid_image?(href)
          replace_anchor_with_image(document, node)
        end
      end

      document.to_html
    end

    private

      MAX_WIDTH = 5000
      MAX_HEIGHT = 5000

      def valid_image?(url)
        sanitized_url = sanitize_url(url)
        return false if sanitized_url.blank?

        # Ensure URL has a valid host before making HTTP request
        uri = URI.parse(sanitized_url)
        return false if uri.host.blank?

        size = FastImage.size(sanitized_url)
        type = FastImage.type(sanitized_url)

        valid_type = %i[jpeg jpg webp png gif svg].include?(type)
        valid_size = size.present? && size[0] <= MAX_WIDTH && size[1] <= MAX_HEIGHT

        valid_type && valid_size
      rescue FastImage::UnknownImageType, FastImage::ImageFetchFailure, URI::InvalidURIError
        false
      end

      def sanitize_url(url)
        uri = URI.parse(url)
        CGI.escapeHTML(uri.to_s)
      rescue URI::InvalidURIError
        ""
      end

      def replace_url_with_image(document, node, url)
        img_node = Nokogiri::XML::Node.new "img", document
        img_node["src"] = url
        img_node["pagecord"] = "true"
        node.add_next_sibling(img_node)
        node.content = node.content.gsub(url, "")
      end

      def replace_anchor_with_image(document, node)
        img_node = Nokogiri::XML::Node.new "img", document
        img_node["src"] = node["href"]
        img_node["pagecord"] = "true"
        node.replace(img_node)
      end
  end
end
