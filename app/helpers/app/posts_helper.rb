module App::PostsHelper
  def publish_button_text(post, model_name: nil)
    name = model_name || infer_model_name(post)
    if post.persisted?
      if post.published?
        "Update #{name}"
      else
        "Publish #{name}"
      end
    else
      "Publish #{name}"
    end
  end

  def draft_button_text(post, model_name: nil)
    if post.persisted?
      if post.published?
        "Unpublish"
      else
        "Update Draft"
      end
    else
      "Save Draft"
    end
  end

  private

    def infer_model_name(post)
      if post.page?
        if post.home_page?
          "Home Page"
        else
          "Page"
        end
      else
        "Post"
      end
    end
end
