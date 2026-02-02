module PricingHelper
  DISCOUNTED_COUNTRIES = %w[IN BR CN].freeze
  DISCOUNTED_PRICES = { monthly: "2.50", annual: "19" }.freeze

  def localised_price(plan = :annual)
    if DISCOUNTED_COUNTRIES.include?(request.headers["CF-IPCountry"])
      DISCOUNTED_PRICES[plan.to_sym]
    else
      Subscription.price(plan)
    end
  end
end
