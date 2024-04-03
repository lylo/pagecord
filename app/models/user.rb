class User < ApplicationRecord
  include Discard::Model
  include DeliveryEmail, Followable

  before_save :downcase_email_and_username

  has_many :posts, dependent: :destroy
  has_many :access_requests, dependent: :destroy

  validates :username, presence: true,
                       uniqueness: true,
                       length: { minimum: Username::MIN_LENGTH, maximum: Username::MAX_LENGTH },
                       format: { with: Username::FORMAT }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def verify!
    self.update! verified: true
  end

  private

    def downcase_email_and_username
      self.email = email.downcase
      self.username = username.downcase
    end
end
