module Html
  class StripActionTextAttachments < Transformation
    def transform(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      doc.css("action-text-attachment").each do |attachment|
        if img = attachment.at_css("img")
          figure = img.parent
          figure.replace(img) if figure.name == "figure"
          attachment.replace(img)
        end
      end

      doc.to_html
    end
  end
end
