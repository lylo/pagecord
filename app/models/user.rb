class User < ApplicationRecord
  include Discard::Model
  include Onboardable, Followable, Subscribable

  has_secure_password validations: false

  has_one :blog, dependent: :destroy, inverse_of: :user
  has_many :access_requests, dependent: :destroy
  has_many :email_change_requests, dependent: :destroy

  accepts_nested_attributes_for :blog

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  normalizes :email, with: -> { it.downcase.strip }
  validates :password, length: { minimum: 12 }, allow_nil: true, if: -> { password.present? }
  validates :password, confirmation: true, if: -> { password.present? }

  def verify!
    self.update! verified: true
  end

  def search_indexable?
    self.created_at&.before?(1.week.ago) || subscribed?
  end

  def pending_email_change_request
    email_change_requests.active.pending.order(created_at: :desc).first
  end

  def has_password?
    password_digest.present?
  end
end
