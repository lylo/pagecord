require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  def setup
    @subscription = Subscription.new(
      cancelled_at: nil,
      next_billed_at: 1.month.from_now,
      plan: :annual
    )
  end

  test "should be subscribed" do
    assert users(:joel).subscribed?
  end

  test "should not be subscribed" do
    assert_not users(:vivian).subscribed?
  end

  test "should be priced at $29 for annual" do
    assert_equal "29", Subscription.price
    assert_equal "29", Subscription.price(:annual)
  end

  test "should be priced at $4 for monthly" do
    assert_equal "4", Subscription.price(:monthly)
  end

  test "active? should return true if not cancelled and not lapsed" do
    assert @subscription.active?
  end

  test "active? should return true if cancelled but not lapsed" do
    @subscription.cancelled_at = Time.current
    assert @subscription.active?
  end

  test "active? should return false if lapsed" do
    @subscription.next_billed_at = 1.month.ago
    assert_not @subscription.active?
  end

  test "cancelled? should return true if cancelled_at is present" do
    @subscription.cancelled_at = Time.current
    assert @subscription.cancelled?
  end

  test "cancelled? should return false if cancelled_at is nil" do
    @subscription.cancelled_at = nil
    assert_not @subscription.cancelled?
  end

  test "lapsed? should return true if next_billed_at is in the past" do
    @subscription.next_billed_at = 1.month.ago
    assert @subscription.lapsed?
  end

  test "lapsed? should return false if next_billed_at is in the future" do
    @subscription.next_billed_at = 1.month.from_now
    assert_not @subscription.lapsed?
  end

  test "lapsed? should return false if next_billed_at is nil" do
    @subscription.next_billed_at = nil
    assert_not @subscription.lapsed?
  end

  test "active? should return false if cancelled and lapsed" do
    @subscription.cancelled_at = Time.current
    @subscription.next_billed_at = 1.month.ago
    assert_not @subscription.active?
  end

  test "plan enum should have monthly, annual, and complimentary values" do
    assert_equal({ "monthly" => "monthly", "annual" => "annual", "complimentary" => "complimentary" }, Subscription.plans)
  end

  test "monthly? should return true for monthly subscription" do
    @subscription.plan = :monthly
    assert @subscription.monthly?
  end

  test "annual? should return true for annual subscription" do
    @subscription.plan = :annual
    assert @subscription.annual?
  end

  test "complimentary? should return true for complimentary subscription" do
    @subscription.plan = :complimentary
    assert @subscription.complimentary?
  end

  test "active_paid scope should include annual subscriptions" do
    subscription = subscriptions(:one)
    assert_includes Subscription.active_paid, subscription
  end

  test "active_paid scope should include monthly subscriptions" do
    subscription = subscriptions(:monthly_subscription)
    assert_includes Subscription.active_paid, subscription
  end

  test "active_paid scope should not include complimentary subscriptions" do
    subscription = subscriptions(:one)
    subscription.update!(plan: :complimentary)
    assert_not_includes Subscription.active_paid, subscription
  end

  test "comped scope should return complimentary subscriptions" do
    subscription = subscriptions(:one)
    subscription.update!(plan: :complimentary)
    assert_includes Subscription.comped, subscription
  end
end
