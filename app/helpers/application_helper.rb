module ApplicationHelper
  def meta_description
    if @post
      post_title(@post)
    elsif @user.present?
      user_bio(@user)
    else
      "Pagecord is a super-simple, minimialist blogging app. All you need is an email address."
    end
  end

  def page_title
    title = "Pagecord"

    if @user&.username
      title = "#{title} | @#{@user.username}"
    end

    if content_for?(:title)
      title = "#{title} | #{content_for(:title)}"
    end

    if @post
      title ="#{title} | #{post_title(@post)}"
    end

    title
  end

  def post_title(post)
    @post_title ||= begin
      if post.title.present?
        post.title.truncate(100)
      else
        sanitized_content = strip_tags(post.content.truncate(140))
        if sanitized_content.blank?
          "Untitled"
        else
          sanitized_content
        end
      end
    end
  end

  def user_bio(user)
    @user_bio ||= begin
      bio = user.bio.present? ? strip_tags(user.bio.truncate(140)) : ""
      "Posts from @#{user.username}. #{bio}"
    end
  end
end
