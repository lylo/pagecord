class User < ApplicationRecord
  include Discard::Model
  include Onboardable, Subscribable, PasswordSecured

  has_many :all_blogs, -> { with_discarded }, class_name: "Blog", dependent: :destroy, inverse_of: :user
  has_many :blogs, -> { kept }, inverse_of: :user
  has_many :access_requests, dependent: :destroy
  has_many :email_change_requests, dependent: :destroy
  has_one :unengaged_follow_up, dependent: :destroy

  accepts_nested_attributes_for :blogs

  scope :purgeable_discarded, ->(before:) {
    discarded
      .left_outer_joins(:subscription)
      .where("users.discarded_at < ?", before)
      .where(
        "subscriptions.id IS NULL OR subscriptions.plan = ? OR subscriptions.next_billed_at <= ?",
        Subscription.plans[:complimentary],
        Time.current
      )
  }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  normalizes :email, with: -> { it.downcase.strip }

  def verify!
    self.update! verified: true
  end

  def search_indexable?
    self.created_at&.before?(1.week.ago) || subscribed?
  end

  def blog
    blogs.order(:created_at).first
  end

  def blog_limit
    subscribed? ? Blog::MAX_BLOGS_PAID : Blog::MAX_BLOGS_FREE
  end

  def pending_email_change_request
    email_change_requests.active.pending.order(created_at: :desc).first
  end
end
