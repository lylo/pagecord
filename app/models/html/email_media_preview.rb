module Html
  class EmailMediaPreview < Transformation
    def initialize(post_url)
      @post_url = post_url
    end

    def transform(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      youtube = YoutubeEmailPreview.new

      doc.css("a[href]").each do |link|
        next unless bare_link?(link)

        thumbnail = youtube.thumbnail_url(link["href"])
        link.replace(thumbnail_link(doc, link["href"], thumbnail, "YouTube video thumbnail")) if thumbnail
      end

      doc.traverse do |node|
        url = standalone_text_url(node)
        next unless url

        thumbnail = youtube.thumbnail_url(url)
        node.replace(thumbnail_link(doc, url, thumbnail, "YouTube video thumbnail")) if thumbnail
      end

      doc.css("figure").each do |figure|
        video = figure.at_css("video") or next

        video["poster"] ? video.replace(thumbnail_link(doc, @post_url, video["poster"], "Video thumbnail")) : figure.remove
      end

      doc.to_html
    end

    private

      def thumbnail_link(doc, href, src, alt)
        link = Nokogiri::XML::Node.new("a", doc)
        link["href"] = href
        link["class"] = "email-media-preview"

        image = Nokogiri::XML::Node.new("img", doc)
        image["src"] = src
        image["alt"] = alt
        image["style"] = "display:block;margin:0 auto;max-width:100%;height:auto;"

        link.add_child(image)
        link
      end

      def standalone_text_url(node)
        return unless node.text? && node.ancestors("a").empty?

        url = node.text.strip
        url if url.present? && !url.match?(/\s/)
      end

      def bare_link?(link)
        text = link.text.strip
        href = link["href"].to_s.strip
        return true if href == text

        href_uri = URI.parse(href)
        text_uri = URI.parse(text)
        [ href_uri.scheme, href_uri.host, href_uri.path ] == [ text_uri.scheme, text_uri.host, text_uri.path ]
      rescue URI::Error
        false
      end
  end
end
