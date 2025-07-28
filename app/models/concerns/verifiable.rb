module Verifiable
  extend ActiveSupport::Concern

  included do
    before_create :generate_verification_token, :set_expiration

    scope :active, -> { where("expires_at > ?", Time.current).where(accepted_at: nil) }
    scope :expired, -> { where("expires_at <= ?", Time.current) }
    scope :accepted, -> { where.not(accepted_at: nil) }
    scope :pending, -> { where(accepted_at: nil) }
  end

  def expired?
    expires_at && expires_at <= Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def accept!
    self.accepted_at = Time.current
    save(validate: false)
  end

  private

    def generate_verification_token
      return if token_digest.present?
      self.token_digest = generate_unique_verification_token
    end

    def generate_unique_verification_token
      loop do
        token = SecureRandom.urlsafe_base64
        break token unless self.class.exists?(token_digest: token)
      end
    end

    def set_expiration
      self.expires_at = expiration_duration.from_now unless expires_at.present?
    end

    def expiration_duration
      24.hours
    end
end
