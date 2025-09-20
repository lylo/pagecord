module Html
  class StripParagraphs < Transformation
    def transform(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      if doc.css("p").any?
        doc.css("p").each do |p|
          new_div = Nokogiri::XML::Node.new("div", doc)
          new_div.inner_html = p.inner_html + "<br><br>"
          p.replace(new_div)
        end

        doc.to_html
      else
        html
      end
    end
  end
end
