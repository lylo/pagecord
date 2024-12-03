module SubscriptionsHelper
  def paddle_data_items
    items = { priceId: annual_price_id, quantity: 1 }

    [ items ].to_json
  end

  def paddle_data
    {
      items: paddle_data_items,
      allow_logout: false,
      success_url: thanks_app_settings_subscriptions_path,
      custom_data: { user_id: Current.user.id }.to_json
    }
  end

  def annual_price_id
    if Rails.env.production?
      "pri_01hx8zr3jgp8et0reybmvmhhwb"
    else
      "pri_01hx904w9f1j7vxzacdfr7fsky"
    end
  end
end
