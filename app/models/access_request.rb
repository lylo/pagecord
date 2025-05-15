class AccessRequest < ApplicationRecord
  belongs_to :user, inverse_of: nil

  before_create :generate_token, :set_exiration

  scope :pending, -> { where(accepted_at: nil) }
  scope :active, -> { where("expires_at > ?", Time.current) }
  scope :recently_accepted, -> { where("accepted_at > ?", 5.minutes.ago) }

  def accept!
    self.accepted_at = Time.current
    save!
  end

  def pending?
    accepted_at.nil?
  end

  private

    def generate_token
      self.token_digest = SecureRandom.urlsafe_base64
    end

    def set_exiration
      self.expires_at = 1.day.from_now
    end
end
