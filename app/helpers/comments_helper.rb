module CommentsHelper
  def comments_frame_id(post, page = 1)
    page > 1 ? "comments_#{post.token}_page_#{page}" : "comments_#{post.token}"
  end
end
