require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  def setup
    @subscription = Subscription.new(
      cancelled_at: nil,
      next_billed_at: 1.month.from_now
    )
  end

  test "should be subscribed" do
    assert users(:joel).subscribed?
  end

  test "should not be subscribed" do
    assert_not users(:vivian).subscribed?
  end

  test "should be priced at $29" do
    assert_equal "29", Subscription.price
  end

  test "active? should return true if not cancelled and not lapsed" do
    assert @subscription.active?
  end

  test "active? should return false if cancelled" do
    @subscription.cancelled_at = Time.current
    assert_not @subscription.active?
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
end
