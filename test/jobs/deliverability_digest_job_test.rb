require "test_helper"

class DeliverabilityDigestJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper, SesHelpers

  test "sends a digest when addresses need attention" do
    stub_ses(suppressions: [ ses_suppression("fred@example.com") ])

    assert_enqueued_emails 1 do
      DeliverabilityDigestJob.perform_now
    end
  end

  test "sends a digest when SES health needs attention, even with no addresses to review" do
    stub_ses(sending_enabled: false)

    assert_enqueued_email_with AdminMailer, :deliverability_digest, args: [ 0, "SES has paused sending" ] do
      DeliverabilityDigestJob.perform_now
    end
  end

  test "sends the digest with a warning when SES health can't be checked" do
    stub_ses(suppressions: [ ses_suppression("fred@example.com") ])
      .stubs(:get_account).raises(Seahorse::Client::NetworkingError.new(RuntimeError.new("timed out")))

    assert_enqueued_email_with AdminMailer, :deliverability_digest, args: [ 1, "SES health couldn't be checked" ] do
      DeliverabilityDigestJob.perform_now
    end
  end

  test "sends nothing and clears the nav badge when all is well" do
    Rails.stubs(:cache).returns(ActiveSupport::Cache::MemoryStore.new)
    stub_ses

    assert_no_enqueued_emails do
      DeliverabilityDigestJob.perform_now
    end

    assert_equal 0, DeliverabilityReport.cached_count
  end
end
