module PricingHelper
  def localised_price
    country = request.headers["CF-IPCountry"]

    price = case country
    when "IN", "BR" then 19
    else Subscription.price
    end

    price
  end
end
