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
      dynamic_og_image_for_post(@post)
    elsif @blog
      dynamic_og_image_for_blog(@blog)
    end
  end

  private

    def dynamic_og_image_for_post(post)
      build_dynamic_og_url(
        title: post.display_title,
        subtitle: post.blog.display_name,
        blog: post.blog
      )
    end

    def dynamic_og_image_for_blog(blog)
      build_dynamic_og_url(
        title: blog.display_name,
        subtitle: blog_domain(blog),
        blog: blog
      )
    end

    def build_dynamic_og_url(title:, subtitle:, blog:)
      worker_url = ENV["OG_WORKER_URL"]
      return nil unless worker_url.present?
      return nil unless blog.user.subscribed? # only paid-for accounts have this feature right now
      return nil unless blog.user.subscribed?

      params = {
        title: title,
        blogTitle: subtitle
      }

      params[:avatar] = if blog.avatar.attached?
        # Use :thumb variant (JPEG format) to avoid cdn-cgi proxy issues
        rails_public_blob_url(blog.avatar.variant(:thumb))
      else
        "#{request.protocol}#{request.host_with_port}/pagecord-mark.png"
      end

      # Colors from blog theme
      colors = blog.og_theme_colors
      params[:bgColor] = colors[:bg]
      params[:textColor] = colors[:text]
      params[:accentColor] = colors[:accent]

      if (signing_secret = ENV["OG_SIGNING_SECRET"]).present?
        params[:signature] = generate_og_signature(params, signing_secret)
      end

      "#{worker_url}?#{params.to_query}"
  end

    def blog_domain(blog)
      blog.custom_domain.presence || "#{blog.subdomain}.pagecord.com"
    end

    def generate_og_signature(params, secret)
      # Create canonical string: title|blogTitle|avatar|bgColor|textColor|accentColor
      canonical = [
        params[:title],
        params[:blogTitle],
        params[:avatar] || "",
        params[:bgColor],
        params[:textColor],
        params[:accentColor]
      ].join("|")

      # Generate HMAC-SHA256 signature
      OpenSSL::HMAC.hexdigest(
        "SHA256",
        secret,
        canonical
      )
    end
end
