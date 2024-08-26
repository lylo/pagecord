require "htmlentities"

module ApplicationHelper
  # <meta name="description" content="<%= meta_description %>">
  def meta_description
    if @post
      post_summary(@post)
    elsif @user.present?
      blog_description(@user)
    else
      "Pagecord is a super-simple microblogging / blogging platform. You publish posts by sending an email. Share your thoughts effortlessly without the need for complex tools."
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
      "Pagecord | #{content_for(:title)}"
    elsif @user
      user_title(@user)
    else
      "Pagecord - Effortless blogging from your inbox"
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
      if @user.present?
        image_url "social/open-graph-post.jpg"
      else
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
      summary = sanitized_content(post)
      if summary.blank?
        "Untitled"
      else
        summary.strip
      end
    end

    def sanitized_content(post)
      coder = HTMLEntities.new
      stripped_content = strip_tags(post.content.to_s)
      coder.decode(stripped_content).truncate(140)
    end


    def blog_description(user)
      if user.bio.present?
        strip_tags(user.bio).truncate(140).strip
      else
        user_title(user)
      end
    end
end
