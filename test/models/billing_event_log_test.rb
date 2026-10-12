require "test_helper"

class BillingEventLogTest < ActiveSupport::TestCase
  test "a value cannot break onto a line of its own" do
    io = StringIO.new
    previous = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(io)

    BillingEventLog.record(:webhook_unmatched, blog: "one\n2026-10-11T00:00:00+00:00 INFO [billing] event=subscription_started amount=3900")

    assert_equal 1, io.string.lines.size
    assert_includes io.string, "blog=one_2026-10-11T00:00:00+00:00_INFO_[billing]_event=subscription_started_amount=3900"
  ensure
    Rails.logger = previous
  end
end
