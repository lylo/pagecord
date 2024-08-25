module Html
  class StripParagraphs < Transformation
    def transform(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      doc.css('p').each do |p|
        p.replace(Nokogiri::HTML::DocumentFragment.parse(p.inner_html + '<br><br>'))
      end

      doc.to_html
    end
  end
end