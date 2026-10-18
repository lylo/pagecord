class Mcp::Tools::GetImage < Mcp::Tool
  SIZE = 800

  describe "See one of the blog's images: a post image URL from get_post, the avatar_url from get_appearance, " \
    "or an img src from get_page_markup. " \
    "Returns the image itself, at most #{SIZE}px on its longest side.",
    properties: { url: { type: "string" } }, required: %i[ url ], read_only: true

  def self.perform(blog, url:)
    blob = find_image(blog, url)
    raise Api::BadRequestError, "That file isn't an image Pagecord can resize" unless blob.variable?

    blob.variant(resize_to_limit: [ SIZE, SIZE ], format: :webp, saver: { quality: 80, strip: true }).processed
  end

  class << self
    # A public blob URL ends in the blob's key on the storage host, or carries
    # its signed id on the app's redirect route.
    def find_image(blog, url)
      segments = URI.parse(url).path.split("/").compact_blank
      signed_ids = segments.filter_map { ActiveStorage::Blob.find_signed(it)&.id }

      images(blog).where(key: segments).or(images(blog).where(id: signed_ids)).first or
        raise Api::BadRequestError, "No image on this blog has that URL"
    rescue URI::InvalidURIError
      raise Api::BadRequestError, "That isn't a URL"
    end

    private
      def content(variant)
        { content: [ { type: "image", data: Base64.strict_encode64(variant.download), mimeType: "image/webp" } ] }
      end

      def images(blog)
        rich_texts = ActionText::RichText.where(record: blog.all_posts).select(:id)
        embeds = ActiveStorage::Attachment.where(record_type: "ActionText::RichText", record_id: rich_texts).select(:blob_id)

        ActiveStorage::Blob.where(id: embeds).or(ActiveStorage::Blob.where(id: blog.avatar_attachment&.blob_id))
      end
  end
end
