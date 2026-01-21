require "httparty"

class PaddleApi
  def get_subscription(id)
    get "subscriptions/#{id}"
  end

  def cancel_subscription(id, immediately: false)
    effective_from = immediately ? "immediately" : "next_billing_period"
    post "subscriptions/#{id}/cancel", { effective_from: effective_from }.to_json
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

  private

    PADDLE_CONFIG = Rails.application.config_for(:paddle)

    def headers
      {
        "Authorization" => "Bearer #{PADDLE_CONFIG[:api_key]}",
        "Content-Type" => "application/json"
      }
    end
end
