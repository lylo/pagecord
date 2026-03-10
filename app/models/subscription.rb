class Subscription < ApplicationRecord
  belongs_to :user

  has_many :renewal_reminders, class_name: "Subscription::RenewalReminder", dependent: :destroy

  enum :plan, { monthly: "monthly", annual: "annual", complimentary: "complimentary" }

  scope :comped, -> { where(plan: :complimentary) }
  scope :active_paid, -> {
    where(plan: [ :annual, :monthly ])
      .where(cancelled_at: nil)
      .where("next_billed_at > ?", Time.current)
  }

  def self.price(plan = :annual)
    plan.to_sym == :monthly ? "4" : "29"
  end

  def self.plan_from_price_id(price_id)
    SubscriptionsHelper::PRICE_IDS[:monthly].values.include?(price_id) ? "monthly" : "annual"
  end

  def extend_to(date)
    new_date = Time.zone.parse(date.to_s)
    response = PaddleApi.new.patch("subscriptions/#{paddle_subscription_id}", {
      next_billed_at: new_date.iso8601,
      proration_billing_mode: "do_not_bill"
    }.to_json)
    parsed = JSON.parse(response.body)

    if response.success?
      update!(next_billed_at: new_date)
    else
      raise "Paddle error: #{parsed.dig("error", "detail") || parsed}"
    end
  end

  def active?
    complimentary? || !lapsed?
  end

  def cancelled?
    cancelled_at.present?
  end

  def lapsed?
    return false if complimentary?

    next_billed_at && next_billed_at < Time.current
  end
end
