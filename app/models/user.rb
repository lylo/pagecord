class User < ApplicationRecord
  include Discard::Model
  include DeliveryEmail, Followable, Subscribable

  before_validation :downcase_email_and_username
  before_create :build_blog

  has_one :blog, dependent: :destroy
  has_many :access_requests, dependent: :destroy
  has_rich_text :bio

  validates :username, presence: true, uniqueness: true, length: { minimum: Username::MIN_LENGTH, maximum: Username::MAX_LENGTH }
  validate  :username_valid
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

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

  private

    def downcase_email_and_username
      self.email = email.downcase.strip
      self.username = username.downcase.strip
    end

    def build_blog
      self.blog = Blog.new(user: self) unless self.blog
    end

    def username_valid
      unless Username.valid_format?(username)
        errors.add(:username, "must only use alphanumeric characters, full stops (periods) or underscores")
      end
    end

    def bio_length
      if bio.to_plain_text.length > 500
        errors.add(:bio, "is too long (maximum 500 characters)")
      end
    end
end
