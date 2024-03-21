class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :access_requests, dependent: :destroy

  validates :username, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
