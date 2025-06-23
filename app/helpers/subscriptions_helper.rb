module SubscriptionsHelper
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
