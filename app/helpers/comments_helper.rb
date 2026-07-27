module CommentsHelper
  def comments_enabled?(blog)
    current_features.enabled?(:comments) && blog.accepts_comments?
  end

  def comments_frame_id(post, page = 1)
    page > 1 ? "comments_#{post.token}_page_#{page}" : "comments_#{post.token}"
  end

  def comment_link_url(comment)
    return if comment.link.blank?

    uri = URI.parse(comment.link)
    comment.link if uri.scheme.in?(%w[http https])
  rescue URI::InvalidURIError
    nil
  end
end
