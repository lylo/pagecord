module Html
  # Workaround: Lexxy crashes (error #66) on <figure> children inside
  # attachment nodes. Strip them — Action Text only uses the tag
  # attributes, not the children.
  class StripAttachmentChildren < Transformation
    def transform(html)
      return html unless html.include?("action-text-attachment")

      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      doc.css("action-text-attachment").each { |node| node.children.remove }
      doc.to_html
    end
  end
end
