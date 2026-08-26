class PaddlePayload
  def initialize(data, event_type)
    @data = data || {}
    @event_type = event_type
  end

  def subscription_id
    @data[:id]
  end

  def customer_id
    @data[:customer_id]
  end

  def user_id
    @data.dig(:custom_data, :user_id)
  end

  def checkout_plan
    @data.dig(:custom_data, :plan)
  end

  def next_billed_at
    @data[:next_billed_at]
  end

  def canceled_at
    @data[:canceled_at]
  end

  def origin
    @data[:origin]
  end

  def billing_period_ends_at
    @data.dig(:billing_period, :ends_at)
  end

  def price_id
    required(:items, 0, :price, :id)
  end

  def unit_price
    required(:items, 0, :price, :unit_price, :amount).to_i
  end

  def transaction_unit_price
    required(:details, :line_items, 0, :unit_totals, :total).to_i
  end

  def monthly_billing_cycle?
    cycle = @data[:billing_cycle] || @data.dig(:items, 0, :price, :billing_cycle)

    cycle&.dig(:interval) == "month" && cycle&.dig(:frequency) == 1
  end

  # Paddle sends a cancellation that runs to the end of the term as an update
  # carrying a scheduled change, not as a cancellation.
  def cancellation_scheduled_at
    return unless @data.dig(:scheduled_change, :action) == "cancel"

    @data.dig(:scheduled_change, :effective_at)
  end

  # A plan change bills the new plan and zero-quantity refunds the old one.
  def changed_plan_price_id
    changed_plan_item&.dig(:price, :id)
  end

  def changed_plan_unit_price
    changed_plan_item&.dig(:price, :unit_price, :amount).to_i
  end

  private

    def changed_plan_item
      Array(@data[:items]).find { |item| item[:quantity].to_i > 0 }
    end

    # Paddle's payload shape is a contract. A field going missing is worth a 500
    # and a retry, naming what was missing, rather than a nil reaching a
    # subscription.
    def required(*keys)
      @data.dig(*keys) || raise("Paddle #{@event_type} payload has no #{keys.join(".")}")
    end
end
