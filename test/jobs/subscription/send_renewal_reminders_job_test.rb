require "test_helper"

class Subscription::SendRenewalRemindersJobTest < ActiveJob::TestCase
  def setup
    @subscription = users(:joel).subscription
  end

  test "sends renewal reminder for active paid subscription due in two weeks" do
    @subscription.update!(next_billed_at: 1.week.from_now)

    assert_enqueued_jobs 1 do
      Subscription::SendRenewalRemindersJob.perform_now
    end

    assert @subscription.renewal_reminders.exists?
  end

  test "does not send renewal reminder for cancelled subscription" do
    @subscription.update!(
      cancelled_at: 1.day.ago,
      next_billed_at: 1.week.from_now
    )

    assert_no_enqueued_jobs do
      Subscription::SendRenewalRemindersJob.perform_now
    end

    assert_not @subscription.renewal_reminders.exists?
  end

  test "does not send renewal reminder for complimentary subscription" do
    @subscription.update!(
      complimentary: true,
      next_billed_at: 2.weeks.from_now
    )

    assert_no_enqueued_jobs do
      Subscription::SendRenewalRemindersJob.perform_now
    end

    assert_not @subscription.renewal_reminders.exists?
  end

  test "does not send renewal reminder for lapsed subscription" do
    @subscription.update!(next_billed_at: 1.day.ago)

    assert_no_enqueued_jobs do
      Subscription::SendRenewalRemindersJob.perform_now
    end

    assert_not @subscription.renewal_reminders.exists?
  end

  test "does not send renewal reminder for subscription not due for renewal" do
    @subscription.update!(next_billed_at: 3.weeks.from_now)

    assert_no_enqueued_jobs do
      Subscription::SendRenewalRemindersJob.perform_now
    end

    assert_not @subscription.renewal_reminders.exists?
  end

  test "does not send duplicate renewal reminder for same period" do
    @subscription.update!(next_billed_at: 2.weeks.from_now)

    # Create existing renewal reminder for the same period
    period = Subscription::RenewalReminder.period_for(@subscription.next_billed_at)
    @subscription.renewal_reminders.create!(period: period, sent_at: Time.current)

    assert_no_enqueued_jobs do
      Subscription::SendRenewalRemindersJob.perform_now
    end

    # Should still only have one reminder
    assert_equal 1, @subscription.renewal_reminders.count
  end
end
