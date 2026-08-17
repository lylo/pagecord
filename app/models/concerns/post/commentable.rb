module Post::Commentable
  extend ActiveSupport::Concern

  included do
    has_many :comments, class_name: "Post::Comment", dependent: :destroy
  end

  def comments_open?
    post? && comments_closed_at.nil?
  end

  def comments_visible?
    post? && (comments_open? || comments_count.positive?)
  end

  def close_comments!
    update!(comments_closed: true)
  end

  def reopen_comments!
    update!(comments_closed: false)
  end

  def comments_closed
    comments_closed_at.present?
  end

  def comments_closed=(value)
    closed = ActiveModel::Type::Boolean.new.cast(value)
    self.comments_closed_at = closed ? (comments_closed_at || Time.current) : nil
  end

  # update_columns skips touch_blog along with the rest, and that touch is what
  # invalidates the cached post page.
  def recount_comments!
    update_columns(comments_count: comments.approved.count)
    blog.touch
  end
end
