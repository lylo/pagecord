require "test_helper"

class DeliverabilityDigestJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper, SesHelpers

  setup { stub_ses }

  def stub_postmark(suppressions: [], bounces: [])
    Postmark::ApiClient.any_instance.stubs(:dump_suppressions).returns(suppressions)
    Postmark::ApiClient.any_instance.stubs(:bounces).returns(bounces)
  end

  test "sends a digest when addresses need attention" do
    stub_postmark(suppressions: [
      { email_address: "fred@example.com", suppression_reason: "HardBounce", created_at: 1.day.ago }
    ])

    assert_enqueued_emails 1 do
      DeliverabilityDigestJob.perform_now
    end
  end

  test "does not send a digest for a one-off recoverable failure" do
    stub_postmark(bounces: [ { email: "fred@example.com", type: "Transient", bounced_at: 1.day.ago } ])

    assert_no_enqueued_emails do
      DeliverabilityDigestJob.perform_now
    end
  end

  test "sends a digest when SES health needs attention, even with no addresses to review" do
    stub_postmark
    stub_ses(sending_enabled: false)

    assert_enqueued_email_with AdminMailer, :deliverability_digest, args: [ 0, "SES has paused sending" ] do
      DeliverabilityDigestJob.perform_now
    end
  end

  test "sends the digest with a warning when SES health can't be checked" do
    stub_postmark(suppressions: [ { email_address: "fred@example.com", suppression_reason: "HardBounce", created_at: 1.day.ago } ])
    stub_ses.stubs(:get_account).raises(Seahorse::Client::NetworkingError.new(RuntimeError.new("timed out")))

    assert_enqueued_email_with AdminMailer, :deliverability_digest, args: [ 1, "SES health couldn't be checked: timed out" ] do
      DeliverabilityDigestJob.perform_now
    end
  end

  test "refreshes the nav badge even when there is nothing to report" do
    Rails.stubs(:cache).returns(ActiveSupport::Cache::MemoryStore.new)
    stub_postmark

    DeliverabilityDigestJob.perform_now

    assert_equal 0, DeliverabilityReport.cached_count
  end
end
