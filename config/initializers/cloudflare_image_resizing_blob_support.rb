module CloudflareImageResizingBlobSupport
  def resizable?(image)
    if image.is_a?(ActiveStorage::Blob)
      image.content_type.in?(CloudflareImageResizing::Helper::RESIZABLE_CONTENT_TYPES)
    elsif image.is_a?(ActionText::Attachment)
      image.attachable.content_type.in?(CloudflareImageResizing::Helper::RESIZABLE_CONTENT_TYPES)
    else
      super
    end
  end

  def resized_image(image, options)
    if image.is_a?(ActiveStorage::Blob)
      preload = options.delete(:preload)
      path = rails_public_blob_url(image)

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
    elsif image.is_a?(ActionText::Attachment)
      preload = options.delete(:preload)
      path = rails_public_blob_url(image.attachable)

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
    else
      super
    end
  end
end

Rails.application.config.after_initialize do
  CloudflareImageResizing::Helper.prepend(CloudflareImageResizingBlobSupport)
end
