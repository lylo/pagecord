require "test_helper"

class DeliverabilityDigestJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

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

  test "does not send a digest for a one-off soft bounce" do
    stub_postmark(bounces: [ { email: "fred@example.com", bounced_at: 1.day.ago } ])

    assert_no_enqueued_emails do
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
