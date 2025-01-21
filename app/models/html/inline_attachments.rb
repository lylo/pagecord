module Html
  class InlineAttachments < Transformation
    include AttachmentPreview

    def initialize(attachments)
      @attachments = attachments
    end

    def transform(html)
      document = Nokogiri::HTML.fragment(html)

      @attachments.map do |attachment_pair|
        original = attachment_pair[:original]
        blob = attachment_pair[:blob]
        url = attachment_pair[:url]

        if original.content_disposition&.start_with?("inline")
          handle_inline_attachment(document, original, blob, url)
        end
      end

      document.to_html
    end

    private

      def handle_inline_attachment(document, original, blob, url)
        content_id = original.content_id.gsub(/\A<|>\Z/, "")
        element = document.at_css "img[src='cid:#{content_id}']"

        if element
          node_html = attachment_preview_node(blob, url, original)
          element.replace node_html
        else
          append_attachment_node(document, blob, url, original)
        end
      end
  end
end
