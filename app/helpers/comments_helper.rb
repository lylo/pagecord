module CommentsHelper
  def comments_enabled?(blog)
    current_features.enabled?(:comments) && blog.accepts_comments?
  end

  def comments_frame_id(post, page = 1)
    page > 1 ? "comments_#{post.token}_page_#{page}" : "comments_#{post.token}"
  end
end
