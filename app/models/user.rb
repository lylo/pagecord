class User < ApplicationRecord
  include Discard::Model
  include Onboardable, Subscribable, PasswordSecured

  has_many :blogs, -> { kept }, dependent: :destroy, inverse_of: :user
  has_many :access_requests, dependent: :destroy
  has_many :email_change_requests, dependent: :destroy
  has_one :unengaged_follow_up, dependent: :destroy

  accepts_nested_attributes_for :blogs

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

  def pending_email_change_request
    email_change_requests.active.pending.order(created_at: :desc).first
  end
end
