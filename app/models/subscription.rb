class Subscription < ApplicationRecord
  belongs_to :user

  scope :active, -> { where(cancelled_at: nil).where("next_billed_at > ?", Time.current) }

  def self.price
    "20"
  end

  def active?
    !cancelled? && !lapsed?
  end

  def cancelled?
    cancelled_at.present?
  end

  def lapsed?
    next_billed_at && next_billed_at < Time.current
  end
end
