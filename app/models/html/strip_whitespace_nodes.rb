module Html
  class StripWhitespaceNodes < Transformation
    def transform(html)
      return html unless html.include?("\n")

      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      doc.children.each { |node| node.remove if node.text? && node.content.strip.empty? }
      doc.to_html
    end
  end
end
