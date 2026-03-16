module Html
  # Workaround: Lexxy crashes (error #66) on <figure> children inside
  # gallery attachment nodes. Strip them — Action Text only uses the
  # tag attributes, not the children.
  class StripGalleryAttachmentChildren < Transformation
    def transform(html)
      return html unless html.include?("attachment-gallery")

      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      doc.css("div.attachment-gallery action-text-attachment").each { |node| node.children.remove }
      doc.to_html
    end
  end
end
