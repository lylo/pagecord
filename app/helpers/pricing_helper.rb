module PricingHelper
  # Public pages are cached, so they render the standard price and the price
  # Stimulus controller swaps in the visitor's own from an uncached endpoint.
  def price_tag(plan = :annual)
    tag.span Subscription.price(plan), data: { price_target: "amount", price_plan: plan }
  end
end
