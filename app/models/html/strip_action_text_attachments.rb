module Html
  class StripActionTextAttachments < Transformation
    def transform(html)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      doc.css("action-text-attachment").each do |attachment|
        # Replace the action-text-attachment with its inner content
        # This preserves figure and figcaption elements
        attachment.replace(attachment.children)
      end

      doc.to_html
    end
  end
end
