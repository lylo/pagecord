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

        if original.content_id.present?
          # Remove the beginning and end < >
          content_id = original.content_id[1...-1]
          element = document.at_css "img[src='cid:#{content_id}']"

          node_html = %Q(
            <action-text-attachment sgid="#{blob.attachable_sgid}" content-type="#{original.content_type}" filename="#{original.filename}" filesize="#{blob.byte_size}" previewable="true" url="#{url}">
              <figure class="attachment attachment--preview attachment--#{blob.filename.extension}">
                <img alt="" src="#{url}">
              </figure>
            </action-text-attachment>
          )

          element.replace node_html
        else
          new_node = Nokogiri::XML::Node.new "action-text-attachment", document
          new_node["sgid"] = blob.attachable_sgid
          new_node["content-type"] = original.content_type
          new_node["filename"] = original.filename
          new_node["url"] = url
          new_node["filesize"] = blob.byte_size
          new_node["previewable"] = "true"

          # append the new node to the existing body
          document << new_node
        end
      end

      document.to_html
    end

    def attachments
      @attachments&.map { |attachment| attachment[:blob] }
    end

    private

      # For each attachment, if any, generates an ActiveStorage::Blob
      # and returns a hash of all the attachment/blob pairs
      def extract_and_store_attachments
        @attachments = @mail.attachments.map do |attachment|
          blob = ActiveStorage::Blob.create_and_upload!(
            io: StringIO.new(attachment.body.to_s),
            filename: attachment.filename,
            content_type: attachment.content_type,
          )

          { original: attachment, blob: blob, url: Rails.application.routes.url_helpers.rails_public_blob_url(blob, only_path: true) }
        end
      end
  end
end
