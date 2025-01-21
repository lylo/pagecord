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

        handle_inline_attachment(document, original, blob, url)
      end

      document.to_html
    end

    private

      def handle_inline_attachment(document, original, blob, url)
        return unless original.content_id

        content_id = original.content_id.gsub(/\A<|>\Z/, "")
        element = document.at_css "img[src='cid:#{content_id}']"

        if element
          node_html = attachment_preview_node(blob, url, original)
          element.replace node_html
        end
      end
  end
end
