require "htmlentities"

module ApplicationHelper
  # <meta name="description" content="<%= meta_description %>">
  def meta_description
    if @post
      @post.summary(limit: 160)
    elsif @blog.present?
      blog_description(@blog)
    else
      "The best free blogging platform for the small web. Publish your writing effortlessly, via email or editor. RSS, email newsletter, and more. Get started for free!"
    end
  end

  def blog_title(blog)
    if blog.custom_title?
      blog.title
    else
      "Posts from @#{blog.subdomain}"
    end
  end

  def page_title
    if @post
      if @post.title&.present?
        "#{@post.title} - #{@post.blog.display_name}"
      else
        "#{blog_title(@post.blog)} - #{@post.published_at_in_user_timezone.to_formatted_s(:long)}"
      end
    elsif content_for?(:title)
      content_for(:title)
    elsif @blog
      blog_title(@blog)
    else
      "Pagecord: Independent blogging for the small web"
    end
  end

  def page_type
    if @post
      "article"
    else
      "website"
    end
  end

  def has_open_graph_image?
    open_graph_image.present?
  end

  def open_graph_image
    if @post && @post.open_graph_image.present?
      @post.open_graph_image.url
    elsif @post && @post.first_image.present?
      resized_image_url @post.first_image, width: 1200, height: 630, crop: true
    elsif !custom_domain_request?
      unless @blog.present?
        image_url "social/open-graph.jpg"
      end
    end
  end

  # FIXME remove?
  def content_image_attachments(post)
    post.content_image_attachments
  end

  def canonical_url
    if @post.present? && @post.canonical_url.present?
      @post.canonical_url
    else
      request&.original_url
    end
  end

  private

    # FIXME This is no longer needed.
    def post_title(post)
      post.display_title
    end

    def blog_description(blog)
      if blog.bio.present?
        strip_tags(blog.bio).truncate(140).strip
      else
        blog_title(blog)
      end
    end

  private

    def strip_links(string)
      string.gsub(/https?:\/\/\S+/, "")
    end
end
