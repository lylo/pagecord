require "test_helper"

class Billing::PaddleEventsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

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
    assert_equal cancellation_date.to_i, subscription.next_billed_at.to_i
    assert_not subscription.user.subscribed?, "access should end when the cancellation takes effect"
  end

  # Paddle cancels immediately when it refunds, and sends subscription.updated
  # alongside subscription.canceled with no next_billed_at of its own.
  test "should not restore access when subscription.updated follows a cancellation" do
    subscription = subscriptions(:one)

    cancellation_date = Time.current

    cancelled = payload_for("subscription.canceled", subscription.user)
    cancelled["data"]["canceled_at"] = cancellation_date.iso8601

    updated = payload_for("subscription.updated.cancellation", subscription.user)
    updated["data"]["id"] = "sub_01hvrk1481njzb874tn7wyrksv"
    updated["data"]["status"] = "canceled"
    updated["data"]["canceled_at"] = cancellation_date.iso8601
    updated["data"]["scheduled_change"] = nil

    [ cancelled, updated ].each do |payload|
      json_payload = payload.to_json

      post billing_paddle_events_url,
        params: json_payload,
        headers: {
          "Content-Type" => "application/json",
          "Paddle-Signature" => paddle_signature_for(json_payload)
        }

      assert_response :success
    end

    subscription.reload
    assert_equal cancellation_date.to_i, subscription.next_billed_at.to_i
    assert_not subscription.user.subscribed?
  end

  test "should not create subscription on transaction.payment_failed event" do
    user = users(:vivian)

    payload = payload_for("transaction.payment_failed", user)
    json_payload = payload.to_json

    post billing_paddle_events_url,
      params: json_payload,
      headers: {
        "Content-Type" => "application/json",
        "Paddle-Signature" => paddle_signature_for(json_payload)
      }

    assert_not user.reload.subscribed?
    assert_nil user.subscription
  end

  test "should update next billing date and unit price on transaction.completed event" do
    subscription = subscriptions(:one)
    original_unit_price = subscription.unit_price

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
    assert_equal 2900, subscription.unit_price
  end

  test "should set base unit price on subscription.created" do
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

  test "should ignore unit_price_overrides in subscription webhook" do
    user = users(:vivian)
    payload = payload_for("subscription.created", user)

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
    assert_equal 3000, user.subscription.reload.unit_price
  end

  test "should set annual plan on subscription.created with annual custom_data" do
    user = users(:vivian)
    payload = payload_for("subscription.created", user)
    payload["data"]["custom_data"]["plan"] = "annual"
    json_payload = payload.to_json

    post billing_paddle_events_url,
      params: json_payload,
      headers: {
        "Content-Type" => "application/json",
        "Paddle-Signature" => paddle_signature_for(json_payload)
      }

    assert_response :success
    assert user.subscription.reload.annual?
  end

  test "should set monthly plan on subscription.created with monthly custom_data" do
    user = users(:vivian)
    payload = payload_for("subscription.created.monthly", user)
    json_payload = payload.to_json

    post billing_paddle_events_url,
      params: json_payload,
      headers: {
        "Content-Type" => "application/json",
        "Paddle-Signature" => paddle_signature_for(json_payload)
      }

    assert_response :success
    assert user.subscription.reload.monthly?
  end

  test "should detect monthly plan from billing cycle when no custom_data plan" do
    user = users(:vivian)
    payload = payload_for("subscription.created", user)
    # Remove the plan from custom_data
    payload["data"]["custom_data"].delete("plan")
    # The billing_cycle is already month/1 in the fixture
    json_payload = payload.to_json

    post billing_paddle_events_url,
      params: json_payload,
      headers: {
        "Content-Type" => "application/json",
        "Paddle-Signature" => paddle_signature_for(json_payload)
      }

    assert_response :success
    # Should fall back to monthly detection based on billing_cycle
    assert user.subscription.reload.monthly?
  end

  test "should update plan on transaction.completed with subscription_update origin" do
    subscription = subscriptions(:monthly_subscription)
    assert subscription.monthly?

    payload = payload_for("transaction.completed.plan_change", subscription.user)
    json_payload = payload.to_json

    post billing_paddle_events_url,
      params: json_payload,
      headers: {
        "Content-Type" => "application/json",
        "Paddle-Signature" => paddle_signature_for(json_payload)
      }

    assert_response :success
    subscription.reload
    assert subscription.annual?, "Expected subscription to be annual after plan change"
    assert_equal Subscription.price_id(:annual), subscription.paddle_price_id
  end

  test "should store the new plan's recurring price, not the prorated transaction total, on a small-proration plan change" do
    subscription = subscriptions(:one)
    assert subscription.annual?

    payload = payload_for("transaction.completed.plan_change.small_proration", subscription.user)
    json_payload = payload.to_json

    post billing_paddle_events_url,
      params: json_payload,
      headers: {
        "Content-Type" => "application/json",
        "Paddle-Signature" => paddle_signature_for(json_payload)
      }

    assert_response :success
    subscription.reload
    assert subscription.supporter?
    # The transaction's line-item total (758) is the prorated top-up charged today, not
    # the ongoing recurring price (7500) — the stored unit_price must be the latter.
    assert_equal 7500, subscription.unit_price
  end

  test "should set supporter plan and send welcome email on subscription.created" do
    user = users(:vivian)
    payload = payload_for("subscription.created", user)
    payload["data"]["custom_data"]["plan"] = "supporter"
    json_payload = payload.to_json

    assert_enqueued_emails 1 do
      post billing_paddle_events_url,
        params: json_payload,
        headers: {
          "Content-Type" => "application/json",
          "Paddle-Signature" => paddle_signature_for(json_payload)
        }
    end

    assert_response :success
    assert user.subscription.reload.supporter?
  end

  test "should send supporter welcome email when upgrading to supporter via transaction.completed" do
    subscription = subscriptions(:one)
    assert subscription.annual?

    payload = payload_for("transaction.completed.plan_change.supporter", subscription.user)
    json_payload = payload.to_json

    assert_enqueued_emails 1 do
      post billing_paddle_events_url,
        params: json_payload,
        headers: {
          "Content-Type" => "application/json",
          "Paddle-Signature" => paddle_signature_for(json_payload)
        }
    end

    assert_response :success
    assert subscription.reload.supporter?
  end

  test "should not resend supporter welcome email when plan is already supporter" do
    subscription = subscriptions(:one)
    subscription.update!(plan: :supporter)

    payload = payload_for("transaction.completed.plan_change.supporter", subscription.user)
    json_payload = payload.to_json

    assert_no_enqueued_emails do
      post billing_paddle_events_url,
        params: json_payload,
        headers: {
          "Content-Type" => "application/json",
          "Paddle-Signature" => paddle_signature_for(json_payload)
        }
    end

    assert_response :success
    assert subscription.reload.supporter?
  end

  test "should reconcile plan and unit_price on a subscription.updated downgrade" do
    subscription = subscriptions(:one)
    subscription.update!(plan: :supporter, unit_price: 7500)

    payload = payload_for("subscription.updated.plan_change", subscription.user)
    json_payload = payload.to_json

    assert_no_enqueued_emails do
      post billing_paddle_events_url,
        params: json_payload,
        headers: {
          "Content-Type" => "application/json",
          "Paddle-Signature" => paddle_signature_for(json_payload)
        }
    end

    assert_response :success
    subscription.reload
    assert subscription.annual?, "plan should reconcile to annual from the webhook price id"
    assert_equal 3900, subscription.unit_price, "unit_price should reconcile from the webhook, not stay at the supporter price"
  end

  test "should not dispatch an event type that names an internal method" do
    user = users(:vivian)
    payload = payload_for("subscription.created", user)
    payload["event_type"] = "load_user"
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
    assert_nil user.reload.subscription
  end

  # "subscription_created" is not a Paddle event type, but under send-based dispatch
  # it names the handler method directly. The HANDLERS hash must only match the
  # dotted event names, so this must not create a subscription.
  test "should not dispatch an event type that names a handler method directly" do
    user = users(:vivian)
    payload = payload_for("subscription.created", user)
    payload["event_type"] = "subscription_created"
    json_payload = payload.to_json

    post billing_paddle_events_url,
      params: json_payload,
      headers: {
        "Content-Type" => "application/json",
        "Paddle-Signature" => paddle_signature_for(json_payload)
      }

    assert_response :success
    assert_nil user.reload.subscription
  end

  test "should ignore a request with no Paddle-Signature header" do
    user = users(:vivian)
    json_payload = payload_for("subscription.created", user).to_json

    assert_no_difference "PaddleEvent.count" do
      post billing_paddle_events_url,
        params: json_payload,
        headers: { "Content-Type" => "application/json" }
    end

    assert_response :success
    assert_nil user.reload.subscription
  end

  test "should ignore a request with a malformed or forged Paddle-Signature header" do
    user = users(:vivian)
    json_payload = payload_for("subscription.created", user).to_json

    [ "", "garbage", "ts=123", "h1=abc", "ts=123;h1=deadbeef" ].each do |signature|
      assert_no_difference "PaddleEvent.count" do
        post billing_paddle_events_url,
          params: json_payload,
          headers: {
            "Content-Type" => "application/json",
            "Paddle-Signature" => signature
          }
      end

      assert_response :success
    end

    assert_nil user.reload.subscription
  end

  test "should fall back to customer_id when custom_data carries no user_id" do
    subscription = subscriptions(:one)
    subscription.update!(paddle_customer_id: "ctm_01hvnxx8katrjdh3xjph09mef7")

    payload = payload_for("transaction.completed", subscription.user)
    payload["data"]["custom_data"].delete("user_id")
    payload["data"]["customer_id"] = subscription.paddle_customer_id
    json_payload = payload.to_json

    post billing_paddle_events_url,
      params: json_payload,
      headers: {
        "Content-Type" => "application/json",
        "Paddle-Signature" => paddle_signature_for(json_payload)
      }

    assert_response :success
    assert_equal Time.parse(payload["data"]["billing_period"]["ends_at"]), subscription.reload.next_billed_at
  end

  test "should log a subscription start with the amount actually charged" do
    subscription = subscriptions(:one)
    payload = payload_for("transaction.completed", subscription.user)
    json_payload = payload.to_json

    lines = billing_lines do
      post billing_paddle_events_url,
        params: json_payload,
        headers: {
          "Content-Type" => "application/json",
          "Paddle-Signature" => paddle_signature_for(json_payload)
        }
    end

    line = lines.find { |l| l.include?("event=subscription_started") }
    assert line, "expected a subscription_started line, got: #{lines.inspect}"
    assert_includes line, "blog=#{subscription.user.blog.subdomain}"
    assert_includes line, "amount=2900"
  end

  test "should log the blog even when Paddle sends no blog_subdomain" do
    subscription = subscriptions(:one)
    payload = payload_for("transaction.completed", subscription.user)
    payload["data"]["custom_data"].delete("blog_subdomain")
    json_payload = payload.to_json

    lines = billing_lines do
      post billing_paddle_events_url,
        params: json_payload,
        headers: {
          "Content-Type" => "application/json",
          "Paddle-Signature" => paddle_signature_for(json_payload)
        }
    end

    line = lines.find { |l| l.include?("event=subscription_started") }
    assert_includes line, "blog=#{subscription.user.blog.subdomain}"
  end

  test "should log a scheduled cancellation with the date access ends" do
    subscription = subscriptions(:one)
    payload = payload_for("subscription.updated.cancellation", subscription.user)
    effective_at = 1.month.from_now
    payload["data"]["customer_id"] = "ctm_01hvnxx8katrjdh3xjph09mef7"
    payload["data"]["id"] = "sub_01hvrk1481njzb874tn7wyrksv"
    payload["data"]["scheduled_change"]["effective_at"] = effective_at.iso8601
    json_payload = payload.to_json

    lines = billing_lines do
      post billing_paddle_events_url,
        params: json_payload,
        headers: {
          "Content-Type" => "application/json",
          "Paddle-Signature" => paddle_signature_for(json_payload)
        }
    end

    line = lines.find { |l| l.include?("event=cancel_scheduled") }
    assert line, "expected a cancel_scheduled line, got: #{lines.inspect}"
    assert_includes line, "effective=#{effective_at.to_date.iso8601}"
    assert_includes line, "source=paddle"
  end

  test "should log a plan change from the webhook that flips it, with the old price" do
    subscription = subscriptions(:one)
    subscription.update!(plan: :supporter, unit_price: 7500)
    payload = payload_for("subscription.updated.plan_change", subscription.user)
    json_payload = payload.to_json

    lines = billing_lines do
      post billing_paddle_events_url,
        params: json_payload,
        headers: {
          "Content-Type" => "application/json",
          "Paddle-Signature" => paddle_signature_for(json_payload)
        }
    end

    line = lines.find { |l| l.include?("event=plan_changed") }
    assert line, "expected a plan_changed line, got: #{lines.inspect}"
    assert_includes line, "from=supporter"
    assert_includes line, "from_amount=7500"
    assert_includes line, "plan=annual"
    assert_includes line, "amount=3900"
  end

  test "should not log a plan change when the plan did not change" do
    subscription = subscriptions(:one)
    payload = payload_for("subscription.updated.plan_change", subscription.user)
    json_payload = payload.to_json

    lines = billing_lines do
      post billing_paddle_events_url,
        params: json_payload,
        headers: {
          "Content-Type" => "application/json",
          "Paddle-Signature" => paddle_signature_for(json_payload)
        }
    end

    assert_nil lines.find { |l| l.include?("event=plan_changed") }
  end

  test "should still process the webhook when billing logging fails" do
    subscription = subscriptions(:one)
    payload = payload_for("subscription.canceled", subscription.user)
    payload["data"]["canceled_at"] = Time.current.iso8601
    json_payload = payload.to_json

    BillingEventLog.stubs(:line_for).raises(RuntimeError, "boom")

    post billing_paddle_events_url,
      params: json_payload,
      headers: {
        "Content-Type" => "application/json",
        "Paddle-Signature" => paddle_signature_for(json_payload)
      }

    assert_response :success
    assert subscription.reload.cancelled?
  end

  test "should log a payment failure at checkout as having no existing subscription" do
    user = users(:vivian)
    payload = payload_for("transaction.payment_failed", user)
    json_payload = payload.to_json

    lines = billing_lines do
      post billing_paddle_events_url,
        params: json_payload,
        headers: {
          "Content-Type" => "application/json",
          "Paddle-Signature" => paddle_signature_for(json_payload)
        }
    end

    line = lines.find { |l| l.include?("event=payment_failed") }
    assert line, "expected a payment_failed line, got: #{lines.inspect}"
    assert_includes line, "existing=false"
  end

  private

    def billing_lines
      io = StringIO.new
      previous = Rails.logger
      Rails.logger = ActiveSupport::Logger.new(io)
      yield
      io.string.scan(/\[billing\].*/)
    ensure
      Rails.logger = previous
    end

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
