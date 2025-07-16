class EmailChangeRequest < ApplicationRecord
  belongs_to :user, inverse_of: nil

  before_create :generate_token, :set_expiration

  validates :new_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :new_email_not_taken

  scope :pending, -> { where(accepted_at: nil) }
  scope :active, -> { where("expires_at > ?", Time.current) }

  def accept!
    user.update!(email: new_email)
    self.accepted_at = Time.current
    save!(validate: false)
  end

  private

    def new_email_not_taken
      if User.exists?(email: new_email)
        errors.add(:new_email, "is already in use")
      end
    end

    def generate_token
      self.token_digest = SecureRandom.urlsafe_base64
    end

    def set_expiration
      self.expires_at = 24.hours.from_now unless expires_at.present?
    end
end
