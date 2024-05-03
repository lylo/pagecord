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

        if original.content_id.present?
          # Remove the beginning and end < >
          content_id = original.content_id[1...-1]
          element = document.at_css "img[src='cid:#{content_id}']"

          element.replace "<action-text-attachment sgid=\"#{blob.attachable_sgid}\" content-type=\"#{original.content_type}\" filename=\"#{original.filename}\"></action-text-attachment>"
        else
          new_node = Nokogiri::XML::Node.new "action-text-attachment", document
          new_node['sgid'] = blob.attachable_sgid
          new_node['content-type'] = original.content_type
          new_node['filename'] = original.filename

          # append the new node to the existing body
          document << new_node
        end
      end

      document.to_html
    end

    def attachments
      @attachments&.map{ |attachment| attachment[:blob] }
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

          { original: attachment, blob: blob }
        end
      end
  end
end
