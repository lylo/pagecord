require "test_helper"

class Subscription::RefreshUnitPriceJobTest < ActiveJob::TestCase
  test "a subscription Paddle keeps refusing is reported once and dropped" do
    PaddleApi.any_instance.stubs(:get_subscription).raises(PaddleApi::Error, "not_found")
    Sentry.expects(:capture_exception).once

    perform_enqueued_jobs do
      Subscription::RefreshUnitPriceJob.perform_later(subscriptions(:one))
    end

    assert_no_enqueued_jobs
  end
end
