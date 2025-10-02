require "test_helper"

class Billing::PaddleEventsControllerTest < ActionDispatch::IntegrationTest
  test "should handle subscription.created event" do
    user = users(:vivian)
    payload = payload_for("subscription.created", user)
    json_payload = payload.to_json

    assert_difference "user.paddle_events.count", 1 do
      post billing_paddle_events_url,
        params: json_payload,
        headers: {
          "Content-Type" => "application/json",
          "Paddle-Signature" => paddle_signature_for(json_payload)
        }
    end

    assert_response :success
    assert user.subscribed?
    assert_equal user.id, user.paddle_events.last.payload["data"]["custom_data"]["user_id"]
    assert_equal user.blog.subdomain, user.paddle_events.last.payload["data"]["custom_data"]["blog_subdomain"]
    assert_equal "sub_01hvrk1481njzb874tn7wyrksv", user.subscription.paddle_subscription_id
    assert_equal "pri_01hvnxrgvfsx46m83z6asdbb94", user.subscription.paddle_price_id
    assert_equal 3000, user.subscription.unit_price
  end

  test "should handle subscription.updated event for cancellation" do
    subscription = subscriptions(:one)

    payload = payload_for("subscription.updated.cancellation", subscription.user)
    cancellation_effective_date = 1.month.from_now

    # Make sure customer_id matches what we set above
    payload["data"]["customer_id"] = "ctm_01hvnxx8katrjdh3xjph09mef7"
    payload["data"]["id"] = "sub_01hvrk1481njzb874tn7wyrksv"
    payload["data"]["scheduled_change"]["effective_at"] = cancellation_effective_date.iso8601

    post billing_paddle_events_url,
      params: payload.to_json,
      headers: {
        "Content-Type" => "application/json",
        "Paddle-Signature" => paddle_signature_for(payload.to_json)
      }

    assert_response :success
    assert subscription.reload.cancelled?
    assert_equal cancellation_effective_date.to_i, subscription.cancelled_at.to_i
  end

  test "should handle subscription.canceled event" do
    subscription = subscriptions(:one)

    payload = payload_for("subscription.canceled", subscription.user)
    cancellation_date = Time.current
    payload["data"]["canceled_at"] = cancellation_date.iso8601
    json_payload = payload.to_json

    post billing_paddle_events_url,
      params: json_payload,
      headers: {
        "Content-Type" => "application/json",
        "Paddle-Signature" => paddle_signature_for(json_payload)
      }

    assert_response :success
    assert subscription.reload.cancelled?
    assert_equal cancellation_date.to_i, subscription.cancelled_at.to_i
  end

  test "should not create subscription on transaction.payment_failed event" do
    user = users(:vivian)

    payload = payload_for("transaction.payment_failed", user)
    json_payload = payload.to_json

    assert_raises do
      post billing_paddle_events_url,
        params: json_payload,
        headers: {
          "Content-Type" => "application/json",
          "Paddle-Signature" => paddle_signature_for(json_payload)
        }
    end

    assert_not user.reload.subscribed?
    assert_nil user.subscription
  end

  test "should update next billing date on transaction.completed event" do
    subscription = subscriptions(:one)

    payload = payload_for("transaction.completed", subscription.user)
    json_payload = payload.to_json

    assert_difference "PaddleEvent.count", 1 do
      post billing_paddle_events_url,
        params: json_payload,
        headers: {
          "Content-Type" => "application/json",
          "Paddle-Signature" => paddle_signature_for(json_payload)
        }
    end

    assert_response :success
    assert_equal subscription.reload.next_billed_at, Time.parse(payload["data"]["billing_period"]["ends_at"])
  end

  test "should use base unit price when no overrides present" do
    user = users(:vivian)
    payload = payload_for("subscription.created", user)
    json_payload = payload.to_json

    post billing_paddle_events_url,
      params: json_payload,
      headers: {
        "Content-Type" => "application/json",
        "Paddle-Signature" => paddle_signature_for(json_payload)
      }

    assert_response :success
    assert_equal 3000, user.subscription.reload.unit_price
  end

  test "should use override unit price when present" do
    user = users(:vivian)
    payload = payload_for("subscription.created", user)

    # Add unit price overrides to the payload
    payload["data"]["items"][0]["price"]["unit_price_overrides"] = [
      {
        "country_codes" => [ "BR", "IN" ],
        "unit_price" => { "amount" => "1900", "currency_code" => "USD" }
      }
    ]

    json_payload = payload.to_json

    post billing_paddle_events_url,
      params: json_payload,
      headers: {
        "Content-Type" => "application/json",
        "Paddle-Signature" => paddle_signature_for(json_payload)
      }

    assert_response :success
    assert_equal 1900, user.subscription.reload.unit_price
  end

  private

    def payload_for(event_type, user)
      json_payload = File.read(Rails.root.join("test", "fixtures", "billing", "#{event_type}.json"))
      data = JSON.parse(json_payload)
      data["data"]["custom_data"] ||= {}
      data["data"]["custom_data"]["user_id"] = user.id
      data["data"]["custom_data"]["blog_subdomain"] = user.blog.subdomain

      # Set next_billed_at to be 1 month from now
      if data["data"]["next_billed_at"]
        data["data"]["next_billed_at"] = 1.month.from_now.iso8601
      end

      data
    end

    def paddle_signature_for(payload)
      ts = Time.current.to_i.to_s
      signed_payload = "#{ts}:#{payload}"

      paddle_config = Rails.application.config_for(:paddle)

      key = paddle_config[:webhook_secret_key]
      digest = OpenSSL::Digest.new("sha256")
      hmac = OpenSSL::HMAC.hexdigest(digest, key, signed_payload)

      "ts=#{ts};h1=#{hmac}"
    end
end
