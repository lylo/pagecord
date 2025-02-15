require "test_helper"

class Subscription::RenewalReminderTest < ActiveSupport::TestCase
  setup do
    @subscription = subscriptions(:one)
    @period = "2025"
  end

  test "valid reminder" do
    reminder = Subscription::RenewalReminder.new(
      subscription: @subscription,
      period: @period,
      sent_at: Time.current
    )

    assert reminder.valid?
  end

  test "requires subscription" do
    reminder = Subscription::RenewalReminder.new(
      period: @period,
      sent_at: Time.current
    )

    assert_not reminder.valid?
    assert_includes reminder.errors[:subscription], "must exist"
  end

  test "requires period" do
    reminder = Subscription::RenewalReminder.new(
      subscription: @subscription,
      sent_at: Time.current
    )

    assert_not reminder.valid?
    assert_includes reminder.errors[:period], "can't be blank"
  end

  test "requires sent_at" do
    reminder = Subscription::RenewalReminder.new(
      subscription: @subscription,
      period: @period
    )

    assert_not reminder.valid?
    assert_includes reminder.errors[:sent_at], "can't be blank"
  end

  test "prevents duplicate periods for same subscription" do
    Subscription::RenewalReminder.create!(
      subscription: @subscription,
      period: @period,
      sent_at: Time.current
    )

    duplicate = Subscription::RenewalReminder.new(
      subscription: @subscription,
      period: @period,
      sent_at: Time.current
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:period], "has already been taken"
  end

  test ".period_for returns year as string" do
    date = Date.new(2025, 2, 14)
    assert_equal "2025", Subscription::RenewalReminder.period_for(date)
  end
end
