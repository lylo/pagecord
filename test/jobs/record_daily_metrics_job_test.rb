require "test_helper"

class RecordDailyMetricsJobTest < ActiveSupport::TestCase
  test "records a snapshot for the day" do
    RecordDailyMetricsJob.perform_now

    assert_equal Subscription.active_paid.count, value_for("paid_subscribers")
    assert_equal User.kept.count, value_for("total_users")
    assert_equal Subscription.comped.count, value_for("comped_subscribers")
  end

  test "mrr counts a twelfth of the yearly plans" do
    RecordDailyMetricsJob.perform_now

    # Three annual at 2000 plus one monthly at 400: 500 + 400.
    assert_equal 900, value_for("mrr_cents")
  end

  test "re-running a day updates the values in place" do
    RecordDailyMetricsJob.perform_now
    subscriptions(:one).update!(cancelled_at: Time.current)

    assert_no_difference -> { Rollup.count } do
      RecordDailyMetricsJob.perform_now
    end

    assert_equal Subscription.active_paid.count, value_for("paid_subscribers")
    assert_equal 1, value_for("churning_subscribers")
  end

  test "each day gets its own row" do
    RecordDailyMetricsJob.perform_now

    travel 1.day do
      assert_difference -> { Rollup.count }, metric_count do
        RecordDailyMetricsJob.perform_now
      end
    end
  end

  private

    def metric_count
      RecordDailyMetricsJob.new.send(:metrics).size
    end

    def value_for(name)
      Rollup.find_by(name: name, interval: "day", time: Date.current).value
    end
end
