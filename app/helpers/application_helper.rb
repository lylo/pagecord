module ApplicationHelper
  # <meta name="description" content="<%= meta_description %>">
  def meta_description
    if @post
      post_summary(@post)
    elsif @user.present?
      blog_description(@user)
    else
      "Effortless blogging from your inbox. All you need is an email address."
    end
  end

  def page_title
    if @post
      post_title(@post)
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
    if @post && @post.attachments.any?
      rails_public_blob_url @post.attachments.first
    elsif @post && @post.open_graph_image.present?
      @post.open_graph_image.url
    elsif @user.custom_domain&.blank?
      image_url "social/open-graph.png"
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
      sanitized_content = strip_tags(post.content.to_s.truncate(140))
      if sanitized_content.blank?
        "Untitled"
      else
        sanitized_content.strip
      end
  end

    def blog_description(user)
      if user.bio.present?
        strip_tags(user.bio.truncate(140)).strip
      else
        user_title(user)
      end
    end
end
