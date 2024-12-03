require "htmlentities"

module ApplicationHelper
  # <meta name="description" content="<%= meta_description %>">
  def meta_description
    if @post
      post_summary(@post)
    elsif @user.present?
      blog_description(@user)
    else
      "Pagecord is the most effortless way to publish your writing online for free. Publish your writing by sending an email, or using our delightfully simple editor."
    end
  end

  def page_title
    if @post
      if @post.title&.present?
        @post.title.truncate(100).strip
      else
        "@#{@post.user.username} - #{@post.published_at.to_formatted_s(:long)}"
      end
    elsif content_for?(:title)
      content_for(:title)
    elsif @user
      user_title(@user)
    else
      "Pagecord - Publish your writing effortlessly from your inbox"
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
    @post && (@post.attachments.any? || @post.open_graph_image.present?)
  end

  def open_graph_image
    if @post && @post.open_graph_image.present?
      @post.open_graph_image.url
    elsif @post && @post.attachments.any?
      rails_public_blob_url @post.attachments.first
    elsif !custom_domain_request?
      unless @user.present?
        image_url "social/open-graph.jpg"
      end
    end
  end

  private

    def user_title(user)
      if user.custom_title?
        user.title
      else
        "Posts from @#{user.username}"
      end
    end

    def post_title(post)
      if post.title.present?
        post.title.truncate(100).strip
      else
        post_summary(post)
      end
    end

    def post_summary(post)
      summary = post.content.to_plain_text
      if summary.blank?
        "Untitled"
      else
        strip_links summary
      end
    end

    def blog_description(user)
      if user.bio.present?
        strip_tags(user.bio).truncate(140).strip
      else
        user_title(user)
      end
    end

  private

    def strip_links(string)
      string.gsub(/https?:\/\/\S+/, "")
    end
end
