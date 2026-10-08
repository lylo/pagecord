module Html
  class CardExcerpt < Transformation
    BLOCKS = "p, div, h1, h2, h3, h4, h5, h6, li, blockquote, pre".freeze

    def initialize(limit: nil)
      @limit = limit
    end

    def transform(html)
      doc = Nokogiri::HTML::DocumentFragment.parse("<div>#{html}</div>").at("div")
      doc.css("action-text-attachment, figure, script, style, sup[data-footnote-ref], ol[data-footnotes]").each(&:remove)
      doc.css("br").each { |br| br.replace("\n") }

      paragraphs(doc).map { |text| "<p>#{ERB::Util.html_escape(text).gsub("\n", "<br>")}</p>" }.join
    end

    private

      def paragraphs(doc)
        nodes = doc.at_css(BLOCKS) ? doc.css(BLOCKS).lazy.reject { |node| node.at_css(BLOCKS) } : [ doc ]
        texts = nodes.lazy.map { |node| node.text.lines.map(&:squish).reject(&:blank?).join("\n") }.reject(&:blank?)
        @limit ? shorten(texts) : texts.to_a
      end

      def shorten(texts)
        remaining = @limit

        texts.each_with_object([]) do |text, kept|
          if text.length > remaining
            kept << text.truncate(remaining, separator: " ") if remaining > 3
            break kept
          end

          kept << text
          remaining -= text.length
        end
      end
  end
end
