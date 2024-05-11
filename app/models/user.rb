class User < ApplicationRecord
  include Discard::Model
  include DeliveryEmail, Followable, Subscribable

  before_save :downcase_email_and_username
  after_update :record_custom_domain_change

  has_many :posts, dependent: :destroy
  has_many :access_requests, dependent: :destroy
  has_many :custom_domain_changes, dependent: :destroy

  validates :username, presence: true,
                       uniqueness: true,
                       length: { minimum: Username::MIN_LENGTH, maximum: Username::MAX_LENGTH },
                       format: { with: Username::FORMAT }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :custom_domain, uniqueness: true, allow_blank: true, format: { with: /\A(?!:\/\/)([a-zA-Z0-9](?:[a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,63}\z/ }
  validate :restricted_domain

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

  def custom_title?
    is_premium? && title.present?
  end

  def domain_changed?
    # we don't want a nil to "" to be considered a domain change
    nil_to_blank_change = (custom_domain_previously_was.nil? && custom_domain.blank?) ||
      (custom_domain_previously_was.blank? && custom_domain.nil?)

    custom_domain_previously_changed? && !nil_to_blank_change
  end


  private

    def downcase_email_and_username
      self.email = email.downcase
      self.username = username.downcase
    end

    def restricted_domain
      restricted_domains = %w[pagecord.com]

      if restricted_domains.include?(custom_domain)
        errors.add(:custom_domain, "is restricted")
      end
    end

    def record_custom_domain_change
      if domain_changed?
        self.custom_domain_changes.create!(custom_domain: custom_domain)
      end
    end
end
