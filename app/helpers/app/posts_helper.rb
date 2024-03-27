module App::PostsHelper
  def post_title(post)
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
