class Subscription < ApplicationRecord
  belongs_to :user

  has_many :renewal_reminders, class_name: "Subscription::RenewalReminder", dependent: :destroy

  enum :plan, { monthly: "monthly", annual: "annual", supporter: "supporter", complimentary: "complimentary" }

  scope :comped, -> { where(plan: :complimentary) }
  scope :active_paid, -> {
    where(plan: [ :annual, :monthly, :supporter ])
      .where(cancelled_at: nil)
      .where("next_billed_at > ?", Time.current)
  }
  scope :churning, -> { where.not(cancelled_at: nil).where("next_billed_at > ?", Time.current) }

  # A callback rather than call sites: cancelled_at is set from the in-app cancel, the
  # subscription.canceled webhook, the subscription.updated webhook with a scheduled
  # cancel, and cancellations made in Paddle's own portal. Resuming nils it, so the
  # presence guard keeps that quiet.
  after_update_commit :record_churn, if: -> { saved_change_to_cancelled_at? && cancelled_at.present? }

  def self.price(plan = :annual)
    case plan.to_sym
    when :monthly then "4"
    when :supporter then "75"
    else "39"
    end
  end

  def self.plan_from_price_id(price_id)
    SubscriptionsHelper::PRICE_IDS.find { |_, ids| ids.values.include?(price_id) }&.first&.to_s || "annual"
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

  private

    # Time.current, not cancelled_at: a scheduled cancel sets cancelled_at to the end of
    # the paid period, which would file the churn in the future. The day they told us is
    # the churn date; the day the money stops shows up in the mrr_cents series.
    def record_churn
      Churn.record(user, :subscription_cancelled)
    end
end
