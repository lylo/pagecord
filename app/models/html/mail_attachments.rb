module Html
  class MailAttachments < Transformation
    def initialize(mail)
      @mail = mail
    end

    def transform(html)
      document = Nokogiri::HTML.fragment(html)

      extract_and_store_attachments.map do |attachment_pair|
        original = attachment_pair[:original]
        blob = attachment_pair[:blob]
        url = attachment_pair[:url]

        if original.content_disposition&.start_with?("inline")
          if original.content_id.present?
            handle_inline_attachment(document, original, blob, url)
          else
            handle_multipart_inline(document, original, blob, url)
          end
        else
          append_attachment_node(document, original, blob, url)
        end
      end

      document.to_html
    end

    def attachments
      @attachments&.map { |attachment| attachment[:blob] }
    end

    private

      def handle_inline_attachment(document, original, blob, url)
        content_id = original.content_id.gsub(/\A<|>\Z/, "")
        element = document.at_css "img[src='cid:#{content_id}']"

        if element
          node_html = build_preview_node(blob, url, original)
          element.replace node_html
        else
          append_attachment_node(document, blob, url, original)
        end
      end

      def handle_multipart_inline(document, original, blob, url)
        node = build_preview_node(blob, url, original)
        document.children.first ? document.children.first.before(node) : document.add_child(node)
      end

      def build_preview_node(blob, url, original)
        %Q(
          <action-text-attachment sgid="#{blob.attachable_sgid}" content-type="#{original.content_type}"
            filename="#{original.filename}" filesize="#{blob.byte_size}" previewable="true" url="#{url}">
            <figure class="attachment attachment--preview attachment--#{blob.filename.extension}">
              <img alt="" src="#{url}">
            </figure>
          </action-text-attachment>
        )
      end

      def append_attachment_node(document, original, blob, url)
        new_node = Nokogiri::XML::Node.new "action-text-attachment", document
        new_node["sgid"] = blob.attachable_sgid
        new_node["content-type"] = original.content_type
        new_node["filename"] = original.filename
        new_node["url"] = url
        new_node["filesize"] = blob.byte_size
        new_node["previewable"] = "true"

        document << new_node
      end

      # For each attachment, if any, generates an ActiveStorage::Blob
      # and returns a hash of all the attachment/blob pairs
      def extract_and_store_attachments
        @attachments = @mail.attachments.map do |attachment|
          blob = ActiveStorage::Blob.create_and_upload!(
            io: StringIO.new(attachment.body.to_s),
            filename: attachment.filename,
            content_type: attachment.content_type,
          )

          { original: attachment, blob: blob, url: Rails.application.routes.url_helpers.rails_blob_url(blob, only_path: true) }
        end
      end
  end
end
