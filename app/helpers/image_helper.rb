module ImageHelper
  def resized_image_url(blob, width:, height:)
    cloudflare_enabled = Rails.configuration.x.cloudflare_image_resizing.present?

    if cloudflare_enabled
      public_url = rails_public_blob_url(blob)
      base_url = "https://#{Rails.configuration.x.domain}"

      "#{base_url}/cdn-cgi/image/width=#{width},height=#{height},format=webp,quality=90/#{public_url}"
    else
      variant = blob.variant(
        resize_to_limit: [ width, height ],
        format: :webp,
        saver: { quality: 90, strip: true, compression: 6 }
      )
      rails_public_blob_url(variant)
    end
  end
end
