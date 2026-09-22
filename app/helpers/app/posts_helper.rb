module App::PostsHelper
  def publish_button_text(post, model_name: nil, short: false)
    verb = post.persisted? && post.published? ? "Update" : "Publish"
    short ? verb : "#{verb} #{model_name || infer_model_name(post)}"
  end

  def settings_customised?(post)
    post.hidden? || post.comments_closed || post.tag_list.present? || post.locale.present? ||
      post.canonical_url.present? || post.open_graph_image.attached? || post.open_graph_image_suppressed?
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
