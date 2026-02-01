module SubscriptionsHelper
  PRICE_IDS = {
    monthly: {
      production: "pri_01kgcczhfsbxrbq17q139s2nc6",
      development: "pri_01kgccx380dyd8sv1c5mr7qgh4",
      test: "pri_01kgccx380dyd8sv1c5mr7qgh4"
    },
    annual: {
      production: "pri_01jxfed0p4kpnbxy75pgzzkz78",
      development: "pri_01jxfe5399nzanxj57bbqk28t4",
      test: "pri_01jxfe5399nzanxj57bbqk28t4"
    }
  }.freeze

  def self.price_id(plan)
    PRICE_IDS[plan.to_sym][Rails.env.to_sym]
  end

  def paddle_environment
    Rails.env.development? ? "sandbox" : "production"
  end

  def paddle_initialize_data
    data = { token: Rails.env.development? ? "test_945b246ef8df8bfe446632bf70b" : "live_8d79ebbaac5c745a173f00967fb" }
    data["pwCustomer"] = { id: Current.user.subscription.paddle_customer_id } if Current.user.subscribed? && !Current.user.subscription.complimentary?
    data.to_json.html_safe
  end

  def monthly_enabled?
    ENV["MONTHLY_ENABLED"] == "true"
  end

  def paddle_annual_data
    paddle_checkout_data(:annual)
  end

  def paddle_monthly_data
    paddle_checkout_data(:monthly)
  end

  def paddle_data
    paddle_annual_data
  end

  def price_id(plan)
    SubscriptionsHelper.price_id(plan)
  end

  private

    def paddle_checkout_data(plan)
      {
        items: [ { priceId: price_id(plan), quantity: 1 } ].to_json,
        allow_logout: false,
        success_url: thanks_app_settings_subscriptions_url,
        custom_data: { user_id: Current.user.id, blog_subdomain: Current.user.blog.subdomain, plan: plan }.to_json
      }
    end
end
