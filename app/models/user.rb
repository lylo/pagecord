class User < ApplicationRecord
  include Discard::Model
  include Onboardable, Followable, Subscribable, PasswordSecured

  has_one :blog, dependent: :destroy, inverse_of: :user
  has_many :access_requests, dependent: :destroy
  has_many :email_change_requests, dependent: :destroy

  accepts_nested_attributes_for :blog

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  normalizes :email, with: -> { it.downcase.strip }

  def verify!
    self.update! verified: true
  end

  def search_indexable?
    self.created_at&.before?(1.week.ago) || subscribed?
  end

  def pending_email_change_request
    email_change_requests.active.pending.order(created_at: :desc).first
  end
end
