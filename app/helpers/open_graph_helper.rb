module OpenGraphHelper
  def has_open_graph_image?
    open_graph_image.present?
  end

  def open_graph_image
    if @post && @post.open_graph_image.present?
      @post.open_graph_image.url
    elsif @post && @post.first_image.present?
      resized_image_url @post.first_image, width: 1200, height: 630, crop: true
    elsif @post
      dynamic_og_image_url(@post)
    end
  end

  private

    def dynamic_og_image_url(post)
      worker_url = ENV["OG_WORKER_URL"]
      return nil unless worker_url.present?
      return nil unless current_features.enabled?(:dynamic_open_graph)

      params = {
        title: post.display_title,
        blogTitle: post.blog.display_name
      }

      if post.blog.avatar.attached?
        # Use JPEG format for OG images (Worker doesn't support WebP)
        params[:avatar] = resized_image_url(post.blog.avatar, width: 160, height: 160, format: :jpeg)
      else
        # Use default Pagecord favicon as avatar
        params[:avatar] = "#{request.protocol}#{request.host_with_port}/apple-touch-icon.png"
      end

      # Add HMAC signature if secret is configured
      signing_secret = ENV["OG_SIGNING_SECRET"]
      if signing_secret.present?
        params[:signature] = generate_og_signature(params, signing_secret)
      end

      "#{worker_url}?#{params.to_query}"
    end

    def generate_og_signature(params, secret)
      # Create canonical string: title|blogTitle|avatar
      canonical = [
        params[:title],
        params[:blogTitle],
        params[:avatar] || ""
      ].join("|")

      # Generate HMAC-SHA256 signature
      OpenSSL::HMAC.hexdigest(
        "SHA256",
        secret,
        canonical
      )
    end
end
