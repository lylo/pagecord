module Html
  class ImageUnfurl < Transformation

    def transform(html)
      document = Nokogiri::HTML.fragment(html)

      document.traverse do |node|
        if node.text? && node.parent.name != "a"
          URI.extract(node.content, ['http', 'https']).each do |url|
            if image_url?(url)
              img_node = Nokogiri::XML::Node.new "img", document
              img_node["src"] = url
              img_node["pagecord"] = "true"
              node.add_next_sibling(img_node)
              node.content = node.content.gsub(url, "")
            end
          end
        elsif node.name == "a" && node.content.include?(node["href"]) && image_url?(node["href"])
          img_node = Nokogiri::XML::Node.new "img", document
          img_node["src"] = node["href"]
          img_node["pagecord"] = "true"
          node.replace(img_node)
        end
      end

      document.to_html
    end

    def image_url?(url)
      url =~ /\.(jpg|jpeg|png|gif|webp)\z/i
    end
  end
end
