module Html
  class StripParagraphs < Transformation
    def transform(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      if doc.css("p").any?
        doc.css("p").each do |p|
          p.replace(Nokogiri::HTML::DocumentFragment.parse(p.inner_html + "<br><br>"))
        end

        doc.to_html
      else
        html
      end
    end
  end
end