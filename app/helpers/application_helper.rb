module ApplicationHelper
  def meta_description
    if @post
      post_title(@post)
    elsif @user.present?
      user_bio(@user)
    else
      "Effortless blogging from your inbox. All you need is an email address."
    end
  end

  def page_title
    if @post
      "#{post_title(@post)} | @#{@user.username}"
    elsif content_for?(:title)
      "Pagecord | #{content_for(:title)}"
    elsif @user&.username
      "Pagecord | @#{@user.username}"
    else
      "Pagecord - Effortless blogging from your inbox"
    end
  end

  def post_title(post)
    if post.title.present?
      post.title.truncate(100).strip
    else
      sanitized_content = strip_tags(post.content.truncate(140))
      if sanitized_content.blank?
        "Untitled"
      else
        sanitized_content.strip
      end
    end
  end

  def user_bio(user)
    @user_bio ||= begin
      bio = user.bio.present? ? strip_tags(user.bio.truncate(140)).strip : ""
      "Posts from @#{user.username}. #{bio}"
    end
  end

  def has_open_graph_image?
    @post && (@post.attachments.any? || @post.open_graph_image.present?)
  end

  def open_graph_image
    if @post && @post.attachments.any?
      rails_blob_url @post.attachments.first
    elsif @post && @post.open_graph_image.present?
      @post.open_graph_image.url
    else
      image_url "social/open-graph.png"
    end
  end
end
