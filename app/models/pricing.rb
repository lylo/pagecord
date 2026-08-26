class Pricing
  # India, Brazil, China, Indonesia, Mexico, Philippines, Vietnam.
  # The cached pages that print a price are split into a discounted and a
  # standard bucket by a Cloudflare rewrite rule holding this same list, so
  # changing it means changing that rule too. See pagecord-ops docs/cloudflare.md.
  DISCOUNTED_COUNTRIES = %w[IN BR CN ID MX PH VN].freeze
  DISCOUNTED_PRICES = { monthly: "2.50", annual: "25", supporter: "50" }.freeze

  def self.for(country_code, plan = :annual)
    if DISCOUNTED_COUNTRIES.include?(country_code)
      DISCOUNTED_PRICES[plan.to_sym]
    else
      Subscription.price(plan)
    end
  end
end
