class User < ApplicationRecord
  include Discard::Model
  include DeliveryEmail

  before_create :downcase_email_and_username

  has_many :posts, dependent: :destroy
  has_many :access_requests, dependent: :destroy

  validates :username, presence: true, uniqueness: true, length: { minimum: 4, maximum: 20 }, format: { with: /\A[a-zA-Z0-9_]+\z/ }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  private

    def downcase_email_and_username
      self.email = email.downcase
      self.username = username.downcase
    end
end
