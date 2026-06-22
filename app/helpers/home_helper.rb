module HomeHelper
  def home_image_path(path, width:, quality: 82)
    source = asset_path(path)

    return source unless Rails.configuration.x.cloudflare_image_resizing

    "/cdn-cgi/image/width=#{width},format=webp,quality=#{quality}/#{source.delete_prefix("/")}"
  end

  def home_image_srcset(path, widths:, quality: 82)
    return unless Rails.configuration.x.cloudflare_image_resizing

    widths.map do |width|
      "#{home_image_path(path, width:, quality:)} #{width}w"
    end.join(", ")
  end
end
