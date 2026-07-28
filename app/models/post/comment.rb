class Post::Comment < ApplicationRecord
  include SpamCheckable

  self.table_name = "post_comments"

  MAX_NAME_LENGTH = 100

  belongs_to :post
  # touch so a parent's updated_at tracks its latest activity, which is what the
  # published list sorts on. Cheaper and steadier than a GREATEST() across a join.
  belongs_to :parent, class_name: "Post::Comment", optional: true, touch: true
  has_many :replies, class_name: "Post::Comment", foreign_key: :parent_id, dependent: :destroy

  validates :name, presence: true, length: { maximum: MAX_NAME_LENGTH }
  validates :message, presence: true, length: { maximum: 8.kilobytes }
  validate :link_format, if: -> { link.present? }
  validate :parent_is_top_level_on_same_post, if: :parent
  validate :one_author_reply_per_comment, on: :create, if: :author?
  validate :post_accepts_comments, on: :create, unless: :author?

  scope :approved, -> { where.not(approved_at: nil) }
  scope :pending, -> { where(approved_at: nil) }
  scope :top_level, -> { where(parent_id: nil) }
  scope :chronologically, -> { order(created_at: :asc, id: :asc) }

  # Not the _commit variants: the count is derived from a COUNT query, so it
  # should roll back with the transaction that changed the comment.
  after_save :recount_post, if: :saved_change_to_approved_at?
  after_destroy :recount_post

  def approved?
    approved_at.present?
  end

  def approve!
    update!(approved_at: Time.current)
  end

  def top_level?
    parent_id.nil?
  end

  def author_reply
    replies.find(&:author?)
  end

  # Threads are one level deep, so a reply has none of its own to go looking for.
  def approved_replies
    top_level? ? replies.select(&:approved?) : []
  end

  # The blogger's own voice: named after the blog, and public the moment it's
  # saved – there's nobody left to approve it.
  def build_author_reply(message)
    post.comments.new(
      parent: self, author: true, approved_at: Time.current,
      name: post.blog.display_name, message: message
    )
  end

  # The link as an href, or nothing at all. Makes the same check link_format
  # makes at write time, so a link that arrived any other way can't reach a page.
  def link_url
    link if link.present? && URI.parse(link).scheme.in?(%w[http https])
  rescue URI::InvalidURIError
    nil
  end

  # Comments collect no email address, so CleanTalk scores on the name and the
  # message alone. See SpamCheckable.
  def email
    nil
  end

  def spam_check_url
    "https://#{post.blog.host}/#{post.slug}"
  end

  private

    def post_accepts_comments
      unless post&.blog&.accepts_comments? && post.comments_open?
        errors.add(:post, "is not accepting comments")
      end
    end

    # Mirrors SocialNavigationItem#validate_url_format
    def link_format
      uri = URI.parse(link)
      errors.add(:link, "must be HTTP or HTTPS") unless uri.scheme.in?(%w[http https])
    rescue URI::InvalidURIError
      errors.add(:link, "is not a valid URL")
    end

    def parent_is_top_level_on_same_post
      errors.add(:parent, "must be on the same post") unless parent.post_id == post_id
      errors.add(:parent, "can't be a reply itself") if parent.parent_id.present?
    end

    def one_author_reply_per_comment
      errors.add(:base, "You've already replied to this comment") if parent&.replies&.exists?(author: true)
    end

    def recount_post
      post.recount_comments!
    end
end
