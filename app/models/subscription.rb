class Subscription < ApplicationRecord
  enum :plan, { annual: "annual", complimentary: "complimentary", lifetime: "lifetime" }

  belongs_to :user

  has_many :renewal_reminders, class_name: "Subscription::RenewalReminder", dependent: :destroy

  scope :comped, -> { where(plan: "complimentary") }
  scope :active_paid, -> {
    where(plan: "annual", cancelled_at: nil).where("next_billed_at > ?", Time.current).or(where(plan: "lifetime"))
  }

  def self.price(plan = :annual)
    plan.to_sym == :lifetime ? "249" : "29"
  end

  def active?
    lifetime? || complimentary? || !lapsed?
  end

  def cancelled?
    cancelled_at.present?
  end

  def lapsed?
    return false if lifetime? || complimentary?

    next_billed_at && next_billed_at < Time.current
  end
end
