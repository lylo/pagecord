class User < ApplicationRecord
  include DeliveryEmail

  before_create :downcase_email

  has_many :posts, dependent: :destroy
  has_many :access_requests, dependent: :destroy

  validates :username, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  private

    def downcase_email
      self.email = email.downcase
    end
end
