module App::PostsHelper
  def publish_button_text(post)
    if post.persisted?
      if post.published?
        "Update Post"
      else
        "Publish Post"
      end
    else
      "Publish Post"
    end
  end

  def draft_button_text(post)
    if post.persisted? && post.published?
      "Unpublish"
    else
      "Save Draft"
    end
  end
end
