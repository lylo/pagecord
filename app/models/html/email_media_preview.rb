module Html
  class EmailMediaPreview < Transformation
    PROVIDERS = [
      YoutubeEmailPreview.new
    ].freeze

    def transform(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      doc.css("a[href]").each do |link|
        replacement = preview_link_for(doc, link["href"])
        next unless replacement && bare_link?(link)

        link.replace(replacement)
      end

      doc.traverse do |node|
        url = standalone_text_url(node)
        replacement = preview_link_for(doc, url)
        next unless replacement

        node.replace(replacement)
      end

      doc.to_html
    end

    private

      def preview_link_for(doc, url)
        return if url.blank?

        PROVIDERS.lazy.filter_map { |provider| provider.preview_link(doc, url) }.first
      end

      def standalone_text_url(node)
        return unless node.text? && node.ancestors("a").empty?

        text = node.text
        url = text.strip
        url if url.present? && text.match?(/\A\s*#{Regexp.escape(url)}\s*\z/)
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
