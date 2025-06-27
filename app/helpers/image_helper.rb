module ImageHelper
  def resized_image_url(blob, width:, height:, crop: false)
    cloudflare_enabled = Rails.configuration.x.cloudflare_image_resizing.present?

    if cloudflare_enabled
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
end
