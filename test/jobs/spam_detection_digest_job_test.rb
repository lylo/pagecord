require "test_helper"

class SpamDetectionDigestJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    # Clean up fixtures for isolated testing
    SpamDetection.delete_all
  end

  test "sends digest email when there are detections needing review" do
    SpamDetection.create!(
      blog: blogs(:joel),
      status: :spam,
      reason: "Spam detected",
      detected_at: Time.current
    )

    assert_enqueued_emails 1 do
      SpamDetectionDigestJob.perform_now
    end
  end

  test "does not send email when no detections need review" do
    SpamDetection.create!(
      blog: blogs(:joel),
      status: :clean,
      reason: "Clean",
      detected_at: Time.current
    )

    assert_no_enqueued_emails do
      SpamDetectionDigestJob.perform_now
    end
  end

  test "does not send email when all detections are reviewed" do
    SpamDetection.create!(
      blog: blogs(:joel),
      status: :spam,
      reason: "Reviewed spam",
      detected_at: Time.current,
      reviewed_at: Time.current
    )

    assert_no_enqueued_emails do
      SpamDetectionDigestJob.perform_now
    end
  end

  test "does not send email for yesterday's detections" do
    SpamDetection.create!(
      blog: blogs(:joel),
      status: :spam,
      reason: "Yesterday",
      detected_at: 1.day.ago
    )

    assert_no_enqueued_emails do
      SpamDetectionDigestJob.perform_now
    end
  end
end
