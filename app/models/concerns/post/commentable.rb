module Post::Commentable
  extend ActiveSupport::Concern

  included do
    has_many :comments, class_name: "Post::Comment", dependent: :destroy
  end

  # Post-level only. The blog-level gate is Blog#accepts_comments?, kept separate
  # so a stream of posts can ask it once rather than once per post.
  def comments_open?
    post? && comments_closed_at.nil?
  end

  # A post that never accepted comments has nothing to show, so the reader sees
  # no button at all. A closed thread with comments still renders them, read-only.
  def comments_visible?
    post? && (comments_open? || comments_count.positive?)
  end

  def close_comments!
    update!(comments_closed: true)
  end

  def reopen_comments!
    update!(comments_closed: false)
  end

  # The post editor needs a checkbox, but the column is a timestamp so a thread
  # closed months ago still says when. Re-closing keeps the original time.
  def comments_closed
    comments_closed_at.present?
  end

  def comments_closed=(value)
    closed = ActiveModel::Type::Boolean.new.cast(value)
    self.comments_closed_at = closed ? (comments_closed_at || Time.current) : nil
  end

  # Approved comments only, so this can't be a counter_cache. Touching the post
  # rolls the fragment key, the ETag and the Cloudflare cache tag.
  # update_columns rather than update!, because a full save would run the post's
  # validations and re-derive text_summary from the Action Text body — a blob
  # query per embedded image — to write one integer. It also means an unrelated
  # validation failure can't make a post's comments unapprovable.
  #
  # Skipping callbacks skips touch_blog with them, so the blog is touched here:
  # that's what rolls the fragment key, the ETag and the Cloudflare cache tag.
  def recount_comments!
    update_columns(comments_count: comments.approved.count)
    blog.touch
  end
end
