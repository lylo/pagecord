module App::PostsHelper
  def publish_button_text(post, model_name: nil, short: false)
    verb = editing_published?(post) ? "Update" : "Publish"
    short ? verb : "#{verb} #{model_name || infer_model_name(post)}"
  end

  def save_button_options(key, saves:, **options)
    return options unless saves

    hotkey_options key, **options,
      title: "Save (#{shortcut "⌘S", "Ctrl+S"})",
      data: { controller: "hotkey", action: command_key_action("s", "hotkey#click") }
  end

  def editing_published?(post)
    post.persisted? && post.published?
  end

  def settings_customised?(post)
    post.hidden? || post.comments_closed || post.tag_list.present? || post.locale.present? ||
      post.canonical_url.present? || post.link_url.present? || post.open_graph_image.attached? || post.open_graph_image_suppressed?
  end

  def draft_button_text(post, model_name: nil, short: false)
    if editing_published?(post)
      "Unpublish"
    elsif short
      "Save"
    else
      post.persisted? ? "Update Draft" : "Save Draft"
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
