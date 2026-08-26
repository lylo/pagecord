require "test_helper"

class SpamDetectionTest < ActiveSupport::TestCase
  setup do
    # Clean up fixtures for isolated testing
    SpamDetection.delete_all
  end

  test "needs_review scope returns spam and uncertain that are not reviewed" do
    SpamDetection.create!(blog: blogs(:joel), status: :spam, reason: "Spam", detected_at: Time.current)
    SpamDetection.create!(blog: blogs(:elliot), status: :uncertain, reason: "Uncertain", detected_at: Time.current)
    SpamDetection.create!(blog: blogs(:vivian), status: :clean, reason: "Clean", detected_at: Time.current)
    SpamDetection.create!(blog: blogs(:annie), status: :spam, reason: "Reviewed", detected_at: Time.current, reviewed_at: Time.current)

    needs_review = SpamDetection.needs_review

    assert_equal 2, needs_review.count
    assert needs_review.all? { |d| d.spam? || d.uncertain? }
    assert needs_review.none?(&:reviewed?)
  end

  test "today scope returns detections from today" do
    SpamDetection.create!(blog: blogs(:joel), status: :spam, reason: "Today", detected_at: Time.current)
    SpamDetection.create!(blog: blogs(:elliot), status: :spam, reason: "Yesterday", detected_at: 1.day.ago)

    today = SpamDetection.today

    assert_equal 1, today.count
    assert_equal "Today", today.first.reason
  end

  test "mark_as_reviewed updates reviewed and reviewed_at" do
    detection = SpamDetection.create!(blog: blogs(:joel), status: :spam, reason: "Test", detected_at: Time.current)

    refute detection.reviewed?
    assert_nil detection.reviewed_at

    detection.mark_as_reviewed!

    assert detection.reviewed?
    assert_not_nil detection.reviewed_at
  end

  test "blog has_one spam_detection" do
    blog = blogs(:joel)
    assert_nil blog.spam_detection

    detection = blog.create_spam_detection!(status: :spam, reason: "Test", detected_at: Time.current)
    assert_equal detection, blog.reload.spam_detection
  end
end
