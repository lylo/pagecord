class User < ApplicationRecord
  include Discard::Model
  include Followable, Subscribable

  has_one :blog, dependent: :destroy, inverse_of: :user
  has_many :access_requests, dependent: :destroy

  accepts_nested_attributes_for :blog

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  normalizes :email, with: -> { it.downcase.strip }

  def verify!
    self.update! verified: true
  end
end
