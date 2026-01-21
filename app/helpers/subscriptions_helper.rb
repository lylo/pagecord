module SubscriptionsHelper
  def paddle_environment
    Rails.env.development? ? "sandbox" : "production"
  end

  def paddle_initialize_data
    data = {
      token: Rails.env.development? ? "test_945b246ef8df8bfe446632bf70b" : "live_8d79ebbaac5c745a173f00967fb"
    }

    if Current.user.subscribed? && !Current.user.subscription.complimentary?
      data["pwCustomer"] = { id: Current.user.subscription.paddle_customer_id.to_s }
    end

    data.to_json.html_safe
  end

  def lifetime_enabled?
    ENV["LIFETIME_ENABLED"] == "true"
  end

  def annual_price_id
    Rails.env.production? ? "pri_01jxfed0p4kpnbxy75pgzzkz78" : "pri_01jxfe5399nzanxj57bbqk28t4"
  end

  def lifetime_price_id
    Rails.env.production? ? "pri_01kfesxmqbbkbqh9xv71kpdfk3" : "pri_01kfet10xfw583xhgarh3hgghd"
  end

  def paddle_annual_data
    paddle_checkout_data(annual_price_id)
  end

  def paddle_lifetime_data
    paddle_checkout_data(lifetime_price_id, plan: "lifetime", lifetime: true)
  end

  private

    def paddle_checkout_data(price_id, plan: nil, lifetime: false)
      custom_data = { user_id: Current.user.id, blog_subdomain: Current.user.blog.subdomain }
      custom_data[:lifetime] = true if lifetime

      {
        items: [ { priceId: price_id, quantity: 1 } ].to_json,
        allow_logout: false,
        success_url: thanks_app_settings_subscriptions_url(plan: plan),
        custom_data: custom_data.to_json
      }
    end
end
