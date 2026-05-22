module PricingHelper
  # India, Brazil, China, Indonesia, Mexico, Philippines, Vietnam
  DISCOUNTED_COUNTRIES = %w[IN BR CN ID MX PH VN].freeze
  DISCOUNTED_PRICES = { monthly: "2.50", annual: "25" }.freeze

  def localised_price(plan = :annual)
    if DISCOUNTED_COUNTRIES.include?(request.headers["CF-IPCountry"])
      DISCOUNTED_PRICES[plan.to_sym]
    else
      Subscription.price(plan)
    end
  end
end
