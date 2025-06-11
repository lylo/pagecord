module PricingHelper
  def localized_price
    country = request.headers["CF-IPCountry"]

    price = case country
    when "IN", "BR" then 19
    else Subscription.price
    end

    puts "Localized price for country #{country}: #{price}"
    price
  end
end
