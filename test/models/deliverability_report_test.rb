require "test_helper"

class DeliverabilityReportTest < ActiveSupport::TestCase
  def report(suppressions: [], bounces: [])
    DeliverabilityReport.new(client: stub(dump_suppressions: suppressions, bounces: bounces))
  end

  def suppression(email, reason: "HardBounce", created_at: 1.day.ago)
    { email_address: email, suppression_reason: reason, created_at: created_at }
  end

  def bounce(email, bounced_at: 1.day.ago)
    { email: email, bounced_at: bounced_at }
  end

  test "suppressions carry their reason and their local subscribers" do
    issue = report(suppressions: [ suppression("fred@example.com", reason: "SpamComplaint") ]).issues.sole

    assert_equal "fred@example.com", issue.email
    assert_equal "SpamComplaint", issue.reason
    assert_equal [ email_subscribers(:one) ], issue.subscribers
    assert issue.actionable?, "a suppression is always worth acting on"
  end

  test "soft bounces are grouped by address and counted" do
    issue = report(bounces: [
      bounce("fred@example.com", bounced_at: 5.days.ago),
      bounce("FRED@example.com", bounced_at: 2.days.ago),
      bounce("fred@example.com", bounced_at: 9.days.ago)
    ]).issues.sole

    assert_nil issue.reason
    assert_equal 3, issue.bounce_count
    assert_in_delta 2.days.ago, issue.last_seen_at, 1.second
  end

  test "bounce timestamps arrive from Postmark as strings" do
    issue = report(bounces: [ bounce("fred@example.com", bounced_at: "2026-08-11T09:24:00Z") ]).issues.sole

    assert_equal Time.utc(2026, 8, 11, 9, 24), issue.last_seen_at.utc
  end

  test "a suppressed address is listed once, with its suppression reason" do
    issue = report(
      suppressions: [ suppression("fred@example.com") ],
      bounces: Array.new(5) { bounce("fred@example.com") }
    ).issues.sole

    assert_equal "HardBounce", issue.reason
    assert_equal 0, issue.bounce_count
  end

  test "addresses with no local subscriber are dropped" do
    assert_empty report(
      suppressions: [ suppression("nobody@example.com") ],
      bounces: [ bounce("nobody-else@example.com") ]
    ).issues
  end

  test "soft bounces are only actionable once they reach the threshold" do
    below = report(bounces: Array.new(DeliverabilityReport::BOUNCE_THRESHOLD - 1) { bounce("fred@example.com") })
    at_threshold = report(bounces: Array.new(DeliverabilityReport::BOUNCE_THRESHOLD) { bounce("fred@example.com") })

    assert_equal 1, below.issues.size
    assert_empty below.actionable
    assert_equal 1, at_threshold.actionable.size
  end

  test "issues are ordered by when the problem was last seen" do
    issues = report(
      suppressions: [ suppression("fred@example.com", created_at: 1.day.ago) ],
      bounces: [ bounce("geoff@gmail.com", bounced_at: 1.week.ago) ]
    ).issues

    assert_equal [ "fred@example.com", "geoff@gmail.com" ], issues.map(&:email)
  end

  test "cache_count! stores the actionable count for the nav badge" do
    Rails.stubs(:cache).returns(ActiveSupport::Cache::MemoryStore.new)

    report(suppressions: [ suppression("fred@example.com") ]).cache_count!

    assert_equal 1, DeliverabilityReport.cached_count
  end
end
