module CloudflareImageResizing
  module Helper
    def resizable?(image)
      if image.is_a?(ActiveStorage::Attachment) || image.is_a?(ActiveStorage::Attached)
        image.content_type.in?(RESIZABLE_CONTENT_TYPES)
      elsif image.is_a?(ActiveStorage::Blob)
        image.content_type.in?(RESIZABLE_CONTENT_TYPES)
      elsif image.is_a?(String)
        extension = File.extname(image)[1..]
        Mime::Type.lookup_by_extension(extension).to_s.in?(RESIZABLE_CONTENT_TYPES)
      else
        false
      end
    end

    def resized_image(image, options)
      preload = options.delete(:preload)

      path = if image.is_a?(ActiveStorage::Attachment) || image.is_a?(ActiveStorage::Attached) || image.is_a?(ActionText::Attachment) || image.is_a?(ActiveStorage::Blob)
        rails_public_blob_url(image)
      else
        image_path(image)
      end

      if resizable?(image)
        if ::Rails.application.config.cloudflare_image_resizing.enabled
          path = "/" + path unless path.starts_with?("/")
          path = "/cdn-cgi/image/" + options.to_param.tr("&", ",") + path
        end

        if preload
          content_for(:cloudflare_image_resizing_preload) do
            preload_link_tag(path, as: :image)
          end
        end
      end

      path
    end
  end
end
