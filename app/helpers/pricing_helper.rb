module PricingHelper
  DISCOUNTED_COUNTRIES = %w[IN BR CN].freeze

  def localised_price(plan = :annual)
    country = request.headers["CF-IPCountry"]

    if DISCOUNTED_COUNTRIES.include?(country)
      plan.to_sym == :lifetime ? 199 : 19
    else
      Subscription.price(plan)
    end
  end
end
