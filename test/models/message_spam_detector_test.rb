require "test_helper"
require "mocha/minitest"

class MessageSpamDetectorTest < ActiveSupport::TestCase
  setup do
    @original_key = ENV["CLEANTALK_AUTH_KEY"]
    @original_detection = ENV["EMAIL_SPAM_DETECTION"]
    ENV["CLEANTALK_AUTH_KEY"] = "test_key"
    ENV["EMAIL_SPAM_DETECTION"] = "true"
    @detector = MessageSpamDetector.new(
      name: "Test User",
      email: "test@example.com",
      message: "Hello, I enjoyed your blog post!"
    )
  end

  teardown do
    ENV["CLEANTALK_AUTH_KEY"] = @original_key
    ENV["EMAIL_SPAM_DETECTION"] = @original_detection
  end

  test "detect returns spam when CleanTalk disallows" do
    CleanTalk.stubs(:check_message).returns({ "allow" => 0, "comment" => "Spam detected" })

    @detector.detect
    assert_equal :spam, @detector.result.status
    assert_equal "Spam detected", @detector.result.reason
    assert @detector.spam?
  end

  test "detect returns not_spam when CleanTalk allows" do
    CleanTalk.stubs(:check_message).returns({ "allow" => 1, "comment" => "Message is clean" })

    @detector.detect
    assert_equal :not_spam, @detector.result.status
    assert_equal "Message is clean", @detector.result.reason
    refute @detector.spam?
  end

  test "detect returns error on API error" do
    CleanTalk.stubs(:check_message).raises(StandardError.new("API Error"))

    @detector.detect
    assert_equal :error, @detector.result.status
    assert_equal "Detection error", @detector.result.reason
  end

  test "detect returns error when missing auth key" do
    ENV["CLEANTALK_AUTH_KEY"] = nil
    detector = MessageSpamDetector.new(name: "Test", email: "t@t.com", message: "Hi")

    detector.detect
    assert_equal :error, detector.result.status
    assert_equal "Missing CleanTalk auth key", detector.result.reason
  end

  test "fail-open: errors do not count as spam" do
    CleanTalk.stubs(:check_message).raises(StandardError.new("Timeout"))

    @detector.detect
    assert_equal :error, @detector.result.status
    refute @detector.spam?
  end

  test "skips detection when EMAIL_SPAM_DETECTION is not set" do
    ENV["EMAIL_SPAM_DETECTION"] = nil

    @detector.detect
    assert_equal :skipped, @detector.result.status
    refute @detector.spam?
  end
end
