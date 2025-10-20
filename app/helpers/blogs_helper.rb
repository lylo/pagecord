module BlogsHelper
  def has_open_graph_image?
    open_graph_image.present?
  end

  def open_graph_image
    if @post && @post.open_graph_image.present?
      @post.open_graph_image.url
    elsif @post && @post.first_image.present?
      resized_image_url @post.first_image, width: 1200, height: 630, crop: true
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
      if @post.title&.present?
        "#{@post.title} - #{@post.blog.display_name}"
      else
        "#{blog_title(@post.blog)} - #{@post.published_at_in_user_timezone.to_formatted_s(:long)}"
      end
    elsif @blog
      blog_title(@blog)
    end
  end

  def blog_title(blog)
    if blog.custom_title?
      blog.title
    else
      "Posts from @#{blog.subdomain}"
    end
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
end
