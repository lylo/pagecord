module SubscriptionsHelper
  def paddle_environment
    Rails.env.development? ? "sandbox" : "production"
  end

  def paddle_initialize_data
    data = {
      token: Rails.env.development? ? "test_945b246ef8df8bfe446632bf70b" : "live_8d79ebbaac5c745a173f00967fb"
    }

    if Current.user.subscribed? && !Current.user.subscription.complimentary?
      data["pwCustomer"] = { id: "#{Current.user.subscription.paddle_customer_id}" }
    end

    data.to_json.html_safe
  end

  def paddle_data_items
    items = { priceId: annual_price_id, quantity: 1 }

    [ items ].to_json
  end

  def paddle_data
    {
      items: paddle_data_items,
      allow_logout: false,
      success_url: thanks_app_settings_subscriptions_url,
      custom_data: { user_id: Current.user.id, blog_subdomain: Current.user.blog.subdomain }.to_json
    }
  end

  def annual_price_id
    if Rails.env.production?
      "pri_01jxfed0p4kpnbxy75pgzzkz78"
    else
      "pri_01jxfe5399nzanxj57bbqk28t4"
    end
  end
end
