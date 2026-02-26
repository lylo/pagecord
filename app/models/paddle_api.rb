require "httparty"

class PaddleApi
  def get_subscription(id)
    get "subscriptions/#{id}"
  end

  def cancel_subscription(id)
    post "subscriptions/#{id}/cancel", { effective_from: "next_billing_period" }.to_json
  end

  def update_subscription_items(subscription_id, price_id)
    patch "subscriptions/#{subscription_id}", {
      items: [ { price_id: price_id, quantity: 1 } ],
      proration_billing_mode: "prorated_immediately"
    }.to_json
  end

  def resume_subscription(subscription_id)
    patch "subscriptions/#{subscription_id}", { scheduled_change: nil }.to_json
  end

  def get_update_payment_method_transaction(subscription_id)
    get "subscriptions/#{subscription_id}/update-payment-method-transaction"
  end

  def get_discount(id)
    get "discounts/#{id}"
  end

  def get(path)
    response = HTTParty.get("#{PADDLE_CONFIG[:base_url]}/#{path}", headers: headers)
    JSON.parse(response.body)
  end

  def post(path, body)
    response = HTTParty.post("#{PADDLE_CONFIG[:base_url]}/#{path}", body: body, headers: headers)
    JSON.parse(response.body)
  end

  def patch(path, body)
    HTTParty.patch("#{PADDLE_CONFIG[:base_url]}/#{path}", body: body, headers: headers)
  end

  private

    PADDLE_CONFIG = Rails.application.config_for(:paddle)

    def headers
      {
        "Authorization" => "Bearer #{PADDLE_CONFIG[:api_key]}",
        "Content-Type" => "application/json"
      }
    end
end
