require "test_helper"

class DeliverabilityReportTest < ActiveSupport::TestCase
  include SesHelpers

  def report(**ses)
    DeliverabilityReport.new(client: stub_ses(**ses))
  end

  test "suppressed addresses carry their reason and their local subscribers" do
    issue = report(suppressions: [ ses_suppression("FRED@example.com", reason: "COMPLAINT") ]).issues.sole

    assert_equal "Spam complaint", issue.reason
    assert_equal [ email_subscribers(:one) ], issue.subscribers
  end

  test "addresses with no local subscriber are dropped" do
    assert_empty report(suppressions: [ ses_suppression("nobody@example.com") ]).issues
  end

  test "issues are ordered by when they were suppressed" do
    issues = report(suppressions: [
      ses_suppression("geoff@gmail.com", last_update_time: 1.week.ago),
      ses_suppression("fred@example.com", last_update_time: 1.day.ago)
    ]).issues

    assert_equal [ "fred@example.com", "geoff@gmail.com" ], issues.map(&:email)
  end

  test "health sums the period's sends, hard bounces and complaints" do
    health = report(sent: 2000, bounces: 20, complaints: 1).health

    assert_equal 2000, health.sent
    assert_in_delta 0.01, health.bounce_rate
    assert_in_delta 0.0005, health.complaint_rate
    assert_nil health.warning
  end

  test "health warns when sending is paused, the account is under review or a rate reaches AWS's review level" do
    assert_match(/paused/, report(sending_enabled: false).health.warning)
    assert_match(/PROBATION/, report(status: "PROBATION").health.warning)
    assert_match(/bounce rate/, report(sent: 100, bounces: 5).health.warning)
    assert_match(/complaint rate/, report(sent: 1000, complaints: 1).health.warning)
    assert_nil report(sent: 0).health.warning
  end

  test "health ignores each rate until enough has been sent to judge it" do
    assert_nil report(sent: 99, bounces: 5).health.warning
    assert_nil report(sent: 999, complaints: 4).health.warning
    assert_match(/complaint rate/, report(sent: 999, complaints: 5).health.warning)
  end

  test "health puts the complaint rate ahead of the bounce rate" do
    assert_match(/complaint rate/, report(sent: 1000, bounces: 50, complaints: 1).health.warning)
  end

  test "a subscriber saved with capitals is matched to the address SES reports" do
    EmailSubscriber.create!(blog: blogs(:vivian), email: "Mixed.Case@Example.com", confirmed_at: 1.day.ago)

    issue = report(suppressions: [ ses_suppression("mixed.case@example.com") ]).issues.sole

    assert_equal [ "Mixed.Case@Example.com" ], issue.subscribers.map(&:email)
  end

  test "health raises when SES can't answer a metric query" do
    ses_client = stub_ses
    ses_client.stubs(:batch_get_metric_data).returns(stub(results: [], errors: [ stub(message: "Internal failure") ]))

    assert_raises(DeliverabilityReport::MetricsError) { DeliverabilityReport.new(client: ses_client).health }
  end

  test "cache_count! stores the issue count for the nav badge" do
    Rails.stubs(:cache).returns(ActiveSupport::Cache::MemoryStore.new)

    report(suppressions: [ ses_suppression("fred@example.com") ]).cache_count!

    assert_equal 1, DeliverabilityReport.cached_count
  end
end
