require "test_helper"

class DeliverabilityReportTest < ActiveSupport::TestCase
  include SesHelpers

  def report(suppressions: [], bounces: [])
    DeliverabilityReport.new(client: stub(dump_suppressions: suppressions, bounces: bounces), ses_client: stub_ses)
  end

  def suppression(email, reason: "HardBounce", created_at: 1.day.ago)
    { email_address: email, suppression_reason: reason, created_at: created_at }
  end

  def bounce(email, type: "Transient", bounced_at: 1.day.ago, message_id: SecureRandom.uuid)
    { email: email, type: type, bounced_at: bounced_at, message_id: message_id }
  end

  test "suppressions carry their reason and their local subscribers" do
    issue = report(suppressions: [ suppression("fred@example.com", reason: "SpamComplaint") ]).issues.sole

    assert_equal "fred@example.com", issue.email
    assert_equal "SpamComplaint", issue.reason
    assert_equal [ email_subscribers(:one) ], issue.subscribers
    assert issue.actionable?, "a suppression is always worth acting on"
  end

  test "an address SES suppresses is actionable, with a hard bounce or complaint reason" do
    issues = DeliverabilityReport.new(
      client: stub(dump_suppressions: [], bounces: []),
      ses_client: stub_ses(suppressions: [ ses_suppression("fred@example.com"), ses_suppression("geoff@gmail.com", reason: "COMPLAINT") ])
    ).actionable

    assert_equal %w[ HardBounce SpamComplaint ], issues.sort_by(&:email).map(&:reason)
    assert_equal %w[ SES ], issues.map(&:source).uniq
  end

  test "an address both providers suppress is listed once, from SES" do
    issue = DeliverabilityReport.new(
      client: stub(dump_suppressions: [ suppression("FRED@example.com", reason: "ManualSuppression") ], bounces: []),
      ses_client: stub_ses(suppressions: [ ses_suppression("fred@example.com") ])
    ).issues.sole

    assert_equal "SES", issue.source
  end

  test "health sums the period's sends, hard bounces and complaints" do
    health = DeliverabilityReport.new(client: stub, ses_client: stub_ses(sent: 2000, bounces: 20, complaints: 1)).health

    assert_equal 2000, health.sent
    assert_in_delta 0.01, health.bounce_rate
    assert_in_delta 0.0005, health.complaint_rate
    assert_nil health.warning
  end

  test "health warns when sending is paused, the account is under review or a rate reaches AWS's review level" do
    warning = ->(**ses) { DeliverabilityReport.new(client: stub, ses_client: stub_ses(**ses)).health.warning }

    assert_match(/paused/, warning.(sending_enabled: false))
    assert_match(/PROBATION/, warning.(status: "PROBATION"))
    assert_match(/bounce rate/, warning.(sent: 100, bounces: 5))
    assert_match(/complaint rate/, warning.(sent: 1000, complaints: 1))
    assert_nil warning.(sent: 0)
  end

  test "health ignores the rates until enough has been sent to judge them" do
    warning = ->(**ses) { DeliverabilityReport.new(client: stub, ses_client: stub_ses(**ses)).health.warning }

    assert_nil warning.(sent: 99, bounces: 5)
    assert_nil warning.(sent: 999, complaints: 4)
    assert_match(/complaint rate/, warning.(sent: 999, complaints: 5))
  end

  test "health puts the complaint rate ahead of the bounce rate" do
    health = DeliverabilityReport.new(client: stub, ses_client: stub_ses(sent: 1000, bounces: 50, complaints: 1)).health

    assert_match(/complaint rate/, health.warning)
  end

  test "a subscriber saved with capitals is matched to the address the provider reports" do
    EmailSubscriber.create!(blog: blogs(:vivian), email: "Mixed.Case@Example.com", confirmed_at: 1.day.ago)

    issue = report(suppressions: [ suppression("mixed.case@example.com") ]).issues.sole

    assert_equal [ "Mixed.Case@Example.com" ], issue.subscribers.map(&:email)
  end

  test "health raises when SES can't answer a metric query" do
    ses_client = stub_ses
    ses_client.stubs(:batch_get_metric_data).returns(stub(results: [], errors: [ stub(message: "Internal failure") ]))

    assert_raises(DeliverabilityReport::MetricsError) { DeliverabilityReport.new(client: stub, ses_client: ses_client).health }
  end

  test "bounces are grouped by address and counted" do
    issue = report(bounces: [
      bounce("fred@example.com", bounced_at: 5.days.ago),
      bounce("FRED@example.com", bounced_at: 2.days.ago),
      bounce("fred@example.com", bounced_at: 9.days.ago)
    ]).issues.sole

    assert_nil issue.reason
    assert_equal "Transient", issue.bounce_type
    assert_equal 3, issue.bounce_count
    assert_in_delta 2.days.ago, issue.last_seen_at, 1.second
  end

  test "retries of one message count once, not once per attempt" do
    issue = report(bounces: Array.new(5) { bounce("fred@example.com", message_id: "same-message") }).issues.sole

    assert_equal 1, issue.bounce_count
    assert_equal "Transient", issue.label
    assert_not issue.actionable?
  end

  test "the badge follows the most recent bounce type" do
    issue = report(bounces: [
      bounce("fred@example.com", type: "Transient", bounced_at: 1.day.ago),
      bounce("fred@example.com", type: "DnsError", bounced_at: 6.days.ago)
    ]).issues.sole

    assert_equal "Transient", issue.type
  end

  test "a single hard failure is actionable, however few times it happened" do
    %w[ HardBounce Blocked BadEmailAddress ].each do |type|
      issue = report(bounces: [ bounce("fred@example.com", type: type) ]).issues.sole
      assert issue.actionable?, "#{type} should be actionable on its own"
    end
  end

  test "a lone transient failure is not actionable" do
    assert_empty report(bounces: [ bounce("fred@example.com", type: "Transient") ]).actionable
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

  test "recoverable failures are only actionable once they reach the threshold" do
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
