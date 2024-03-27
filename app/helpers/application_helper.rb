module ApplicationHelper
  def page_title
    base_title = "Pagecord"
    if @user&.username
      "#{base_title} | @#{@user.username}"
    elsif content_for?(:title)
      "#{base_title} | #{content_for(:title)}"
    else
      base_title
    end
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
