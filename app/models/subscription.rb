class Subscription < ApplicationRecord
  belongs_to :user

  has_many :renewal_reminders, class_name: "Subscription::RenewalReminder", dependent: :destroy

  scope :comped, -> { where(complimentary: true) }
  scope :active_paid, -> { where(cancelled_at: nil).where(complimentary: false).where("next_billed_at > ?", Time.current) }

  def self.price
    "20"
  end

  def active?
    active_paid = !cancelled? && !lapsed?

    complimentary? || active_paid
  end

  def cancelled?
    cancelled_at.present?
  end

  def lapsed?
    return false if complimentary?

    next_billed_at && next_billed_at < Time.current
  end
end
