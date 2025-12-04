module BlogsHelper
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

  def page_type
    if @post
      "article"
    else
      "website"
    end
  end

  def page_title
    if @post
      if @post.home_page?
        blog_title(@post.blog)
      elsif @post.title&.present?
        "#{@post.title} - #{@post.blog.display_name}"
      else
        "#{blog_title(@post.blog)} - #{@post.published_at_in_user_timezone.to_formatted_s(:long)}"
      end
    elsif @blog
      blog_title(@blog)
    end
  end

  def blog_title(blog)
    return blog.seo_title if blog.seo_title.present?
    return blog.title if blog.custom_title?
    "Posts from @#{blog.subdomain}"
  end

  def meta_description
    if @post
      @post.summary(limit: 160)
    elsif @blog.present?
      blog_description(@blog)
    end
  end

  def canonical_url
    if @post.present? && @post.canonical_url.present?
      @post.canonical_url
    elsif @post.present?
      post_url(@post)
    elsif @blog.present?
      blog_home_url(@blog)
    else
      request&.original_url
    end
  end

  def content_type_class
    return "" unless @post

    if @post.home_page?
      "home-page"
    elsif @post.page?
      "page"
    else
      "post"
    end
  end

  private

    def blog_description(blog)
      if blog.bio.present?
        strip_tags(blog.bio).truncate(140).strip
      else
        blog_title(blog)
      end
    end

    def dynamic_og_image_url(post)
      worker_url = ENV["OG_WORKER_URL"]
      return nil unless worker_url.present?
      return nil unless feature?(:dynamic_open_graph, blog: post.blog)

      params = {
        title: post.display_title,
        blogTitle: post.blog.display_name
      }

      if post.blog.avatar.attached?
        avatar_url = resized_image_url(post.blog.avatar, width: 160, height: 160)
        params[:avatar] = avatar_url
        params[:favicon] = avatar_url
      else
        # Use default Pagecord favicon
        params[:favicon] = "#{request.protocol}#{request.host_with_port}/apple-touch-icon.png"
      end

      # Add HMAC signature if secret is configured
      signing_secret = ENV["OG_SIGNING_SECRET"]
      if signing_secret.present?
        params[:signature] = generate_og_signature(params, signing_secret)
      end

      "#{worker_url}?#{params.to_query}"
    end

    def generate_og_signature(params, secret)
      # Create canonical string: title|blogTitle|avatar|favicon
      canonical = [
        params[:title],
        params[:blogTitle],
        params[:avatar] || "",
        params[:favicon] || ""
      ].join("|")

      # Generate HMAC-SHA256 signature
      OpenSSL::HMAC.hexdigest(
        "SHA256",
        secret,
        canonical
      )
    end
end
