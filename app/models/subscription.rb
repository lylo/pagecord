class Subscription < ApplicationRecord
  belongs_to :user

  has_many :renewal_reminders, class_name: "Subscription::RenewalReminder", dependent: :destroy

  PLANS = %w[ monthly annual supporter ].freeze

  PRICE_IDS = {
    monthly: {
      production: "pri_01kgcczhfsbxrbq17q139s2nc6",
      development: "pri_01kgccx380dyd8sv1c5mr7qgh4",
      test: "pri_01kgccx380dyd8sv1c5mr7qgh4"
    },
    annual: {
      production: "pri_01kj7dvn8xc1yee6ppwzda5ykk",
      development: "pri_01jxfe5399nzanxj57bbqk28t4",
      test: "pri_01jxfe5399nzanxj57bbqk28t4"
    },
    supporter: {
      production: "pri_01ky75g6xy1tyddwrax0r3wge4",
      development: "pri_01ky7775szgjfcrvsaf4pxtnyf",
      test: "pri_01ky7775szgjfcrvsaf4pxtnyf"
    }
  }.freeze

  enum :plan, { monthly: "monthly", annual: "annual", supporter: "supporter", complimentary: "complimentary" }

  scope :comped, -> { where(plan: :complimentary) }
  scope :active_paid, -> {
    where(plan: [ :annual, :monthly, :supporter ])
      .where(cancelled_at: nil)
      .where("next_billed_at > ?", Time.current)
  }

  def self.price(plan = :annual)
    case plan.to_sym
    when :monthly then "4"
    when :supporter then "75"
    else "39"
    end
  end

  def self.price_id(plan)
    PRICE_IDS[plan.to_sym][Rails.env.to_sym]
  end

  def self.plan_from_price_id(price_id)
    PRICE_IDS.find { |_, ids| ids.values.include?(price_id) }&.first&.to_s || "annual"
  end

  # Returns nil once the plan has changed, or a symbol naming why it didn't.
  def change_plan_to(new_plan)
    return :unknown_plan unless PLANS.include?(new_plan)

    # Moving from a yearly plan to monthly changes the billing interval, which Paddle reschedules
    # immediately (billing next month) rather than at the current term's end — it would forfeit
    # already-paid time. Not offered; monthly is only chosen at signup.
    return :monthly_from_yearly if new_plan == "monthly" && !monthly?

    response = PaddleApi.new.update_subscription_items(
      paddle_subscription_id, Subscription.price_id(new_plan),
      proration_billing_mode: proration_billing_mode_for(new_plan)
    )

    unless response.success?
      Rails.logger.error "Plan change failed for user #{user_id} (#{paddle_subscription_id} -> #{new_plan}): HTTP #{response.code} #{response.body}"
      return paddle_error_from(response)
    end

    # Optimistically reflect the switch now so the UI is correct even if the
    # subscription.updated webhook is delayed or missed. The webhook still
    # confirms unit_price and the next billing date.
    update!(plan: new_plan, paddle_price_id: Subscription.price_id(new_plan))

    nil
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

    # Downgrades take effect at the next billing cycle and never refund; upgrades bill the difference today.
    def proration_billing_mode_for(new_plan)
      downgrade = Subscription.price(new_plan).to_i < Subscription.price(plan).to_i
      downgrade ? "do_not_bill" : "prorated_immediately"
    end

    def paddle_error_from(response)
      case response.body.to_s
      when /subscription_payment_declined/ then :payment_declined
      when /subscription_update_transaction_balance_less_than_charge_limit/ then :too_close_to_renewal
      else :unknown
      end
    end
end
