require "htmlentities"

module ApplicationHelper
  # <meta name="description" content="<%= meta_description %>">
  def meta_description
    if @post
      post_summary(@post)
    elsif @blog.present?
      blog_description(@blog)
    else
      "Pagecord is the most effortless way to blog, for free. Publish your writing by sending an email, or using our delightfully simple editor."
    end
  end

  def blog_title(blog)
    if blog.custom_title?
      blog.title
    else
      "Posts from @#{blog.name}"
    end
  end

  def page_title
    if @post
      if @post.title&.present?
        @post.title.truncate(100).strip
      else
        "#{blog_title(@post.blog)} - #{@post.published_at.to_formatted_s(:long)}"
      end
    elsif content_for?(:title)
      content_for(:title)
    elsif @blog
      blog_title(@blog)
    else
      "Pagecord - Publish your writing effortlessly. All you need is email"
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
    elsif @post && @post.attachments.any?               # email attachments
      rails_public_blob_url @post.attachments.first
    elsif @post && content_image_attachments(@post).any?  # rich text attachments
      rails_public_blob_url content_image_attachments(@post).first
    elsif !custom_domain_request?
      unless @blog.present?
        image_url "social/open-graph.jpg"
      end
    end
  end

  def content_image_attachments(post)
    post.content.body.attachments.select { |attachment| attachment.try(:image?) }
  end

  def canonical_url
    if @post.present? && @post.canonical_url.present?
      @post.canonical_url
    else
      request&.original_url
    end
  end

  private

    def post_title(post)
      if post.title.present?
        post.title.truncate(100).strip
      else
        post_summary(post)
      end
    end

    def post_summary(post)
      summary = strip_links(post.content.to_plain_text).truncate(140)

      if summary.blank?
        "Untitled"
      else
        summary
      end
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
