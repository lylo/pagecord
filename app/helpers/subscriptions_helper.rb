module SubscriptionsHelper
  def paddle_environment
    Rails.env.development? ? "sandbox" : "production"
  end

  def paddle_initialize_data
    data = { token: Rails.env.development? ? "test_945b246ef8df8bfe446632bf70b" : "live_8d79ebbaac5c745a173f00967fb" }
    data["pwCustomer"] = { id: Current.user.subscription.paddle_customer_id } if Current.user.subscribed? && !Current.user.subscription.complimentary?
    data.to_json.html_safe
  end

  def paddle_annual_data
    paddle_checkout_data(:annual)
  end

  def paddle_monthly_data
    paddle_checkout_data(:monthly)
  end

  def paddle_supporter_data
    paddle_checkout_data(:supporter)
  end

  def paddle_data
    paddle_annual_data
  end

  def price_id(plan)
    Subscription.price_id(plan)
  end

  private

    def paddle_checkout_data(plan)
      {
        items: [ { priceId: price_id(plan), quantity: 1 } ].to_json,
        allow_logout: false,
        success_url: app_settings_subscriptions_thanks_url(plan: plan),
        custom_data: { user_id: Current.user.id, blog_subdomain: Current.blog.subdomain, plan: plan }.to_json
      }
    end
end
