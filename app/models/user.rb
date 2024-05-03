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
  validates :custom_domain, uniqueness: true, allow_blank: true, format: { with: /\A(?!:\/\/)([a-zA-Z0-9](?:[a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,63}\z/ }

  def verify!
    self.update! verified: true
  end

  ADMIN_USERS = %w[olly pagecord]

  def is_admin?
    if Rails.env.production?
      ADMIN_USERS.include? Current.user.username
    else
      Current.user.username == "joel"
    end
  end

  def is_premium?
    %w[olly pagecord lylo teamlight].include?(username) || !Rails.env.production?
  end

  private

    def downcase_email_and_username
      self.email = email.downcase
      self.username = username.downcase
    end
end
