module Html
  class ResolveBlobImages < Transformation
    include Html::AttachmentPreview

    BLOB_URL_PATTERN = %r{/active_storage/blobs/(?:redirect|proxy)/([^/]+)/}.freeze

    # Micropub clients reference uploaded images by blob URL returned from the
    # media endpoint. Convert those <img> tags to Action Text attachments so the
    # blob remains associated with the saved post.
    def transform(html)
      return html unless html&.match?(BLOB_URL_PATTERN)

      doc = Nokogiri::HTML::DocumentFragment.parse(html)

      doc.css("img").each do |img|
        next unless blob = blob_from_url(img["src"])

        node = img.parent&.name == "figure" ? img.parent : img
        node.replace attachment_preview_node(blob, img["src"], attributes: { caption: img["alt"] })
      end

      doc.to_html
    end

    private

      def blob_from_url(url)
        signed_id = url.to_s[BLOB_URL_PATTERN, 1]
        ActiveStorage::Blob.find_signed(signed_id) if signed_id
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        nil
      end
  end
end
