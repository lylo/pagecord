require "fastimage"

module Html
  class ImageUnfurl < Transformation

    def transform(html)
      document = Nokogiri::HTML.fragment(html)

      document.traverse do |node|
        if node.text? && node.parent.name != "a"
          URI.extract(node.content, ['http', 'https']).each do |url|
            if valid_image?(url)
              img_node = Nokogiri::XML::Node.new "img", document
              img_node["src"] = url
              img_node["pagecord"] = "true"
              node.add_next_sibling(img_node)
              node.content = node.content.gsub(url, "")
            end
          end
        elsif node.name == "a" && node.content.include?(node["href"]) && valid_image?(node["href"])
          img_node = Nokogiri::XML::Node.new "img", document
          img_node["src"] = node["href"]
          img_node["pagecord"] = "true"
          node.replace(img_node)
        end
      end

      document.to_html
    end

    private

      MAX_WIDTH = 5000
      MAX_HEIGHT = 5000

      def valid_image?(url)
        size = FastImage.size(url)
        type = FastImage.type(url)

        valid_type = %i[jpeg jpg webp png gif svg].include?(type)
        valid_size = size.present? && size[0] <= MAX_WIDTH && size[1] <= MAX_HEIGHT

        valid_type && valid_size
      rescue FastImage::UnknownImageType, FastImage::ImageFetchFailure
        false
      end
    end
end
