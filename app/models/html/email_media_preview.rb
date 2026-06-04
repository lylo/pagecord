module Html
  class EmailMediaPreview < Transformation
    def transform(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      youtube = YoutubeEmailPreview.new

      doc.css("a[href]").each do |link|
        next unless bare_link?(link)

        replacement = youtube.preview_link(doc, link["href"])
        link.replace(replacement) if replacement
      end

      doc.traverse do |node|
        url = standalone_text_url(node)
        next unless url

        replacement = youtube.preview_link(doc, url)
        node.replace(replacement) if replacement
      end

      doc.to_html
    end

    private

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
      rescue URI::InvalidURIError
        false
      end
  end
end
