module ImageHelper
  # Cloudflare's resizer refuses anything above these and returns error 9413
  # instead of an image. A 24 megapixel camera is nowhere near, but a scanned or
  # stitched photo can be: the first one to hit this was 8736x11648.
  CLOUDFLARE_MAX_AREA = 100_000_000
  CLOUDFLARE_MAX_DIMENSION = 50_000

  def resized_image_url(blob, width:, height:, crop: false)
    cloudflare_enabled = Rails.configuration.x.cloudflare_image_resizing.present?

    if cloudflare_enabled && cloudflare_can_resize?(blob)
      public_url = rails_public_blob_url(blob)
      base_url = "https://#{Rails.configuration.x.domain}"

      options = "width=#{width},height=#{height},format=webp,quality=90"
      options += ",fit=cover,gravity=auto" if crop

      "#{base_url}/cdn-cgi/image/#{options}/#{public_url}"
    else
      resize_method = crop ? :resize_to_fill : :resize_to_limit
      variant = blob.variant(
        resize_method => [ width, height ],
        format: :webp,
        saver: { quality: 90, strip: true, compression: 6 }
      )
      rails_public_blob_url(variant)
    end
  end

  private

    # A blob that hasn't been analysed yet has no dimensions to judge, so it
    # takes the usual path rather than every new image falling back until its
    # analysis job has run.
    def cloudflare_can_resize?(blob)
      width, height = blob.metadata["width"], blob.metadata["height"]
      return true unless width && height

      width * height <= CLOUDFLARE_MAX_AREA &&
        width <= CLOUDFLARE_MAX_DIMENSION &&
        height <= CLOUDFLARE_MAX_DIMENSION
    end
end
