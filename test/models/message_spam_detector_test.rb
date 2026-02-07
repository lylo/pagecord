require "test_helper"
require "mocha/minitest"

class MessageSpamDetectorTest < ActiveSupport::TestCase
  setup do
    @original_token = ENV["OPENAI_ACCESS_TOKEN"]
    @original_detection = ENV["EMAIL_SPAM_DETECTION"]
    ENV["OPENAI_ACCESS_TOKEN"] = "test_token"
    ENV["EMAIL_SPAM_DETECTION"] = "true"
    @detector = MessageSpamDetector.new(
      name: "Test User",
      email: "test@example.com",
      message: "Hello, I enjoyed your blog post!"
    )
  end

  teardown do
    ENV["OPENAI_ACCESS_TOKEN"] = @original_token
    ENV["EMAIL_SPAM_DETECTION"] = @original_detection
  end

  test "detect returns spam classification" do
    mock_response = {
      "choices" => [
        { "message" => { "content" => { classification: "spam", reason: "SEO solicitation" }.to_json } }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    @detector.detect
    assert_equal :spam, @detector.result.status
    assert_equal "SEO solicitation", @detector.result.reason
    assert @detector.spam?
  end

  test "detect returns not_spam classification" do
    mock_response = {
      "choices" => [
        { "message" => { "content" => { classification: "not_spam", reason: "Genuine feedback" }.to_json } }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    @detector.detect
    assert_equal :not_spam, @detector.result.status
    assert_equal "Genuine feedback", @detector.result.reason
    refute @detector.spam?
  end

  test "unknown classification treated as not_spam" do
    mock_response = {
      "choices" => [
        { "message" => { "content" => { classification: "uncertain", reason: "Unclear" }.to_json } }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    @detector.detect
    assert_equal :not_spam, @detector.result.status
    refute @detector.spam?
  end

  test "detect returns error on JSON parse failure" do
    mock_response = {
      "choices" => [
        { "message" => { "content" => "Not JSON" } }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    @detector.detect
    assert_equal :error, @detector.result.status
    assert_equal "Failed to parse AI response", @detector.result.reason
  end

  test "detect returns error on API error" do
    OpenAI::Client.any_instance.stubs(:chat).raises(StandardError.new("API Error"))

    @detector.detect
    assert_equal :error, @detector.result.status
    assert_equal "Detection error", @detector.result.reason
  end

  test "detect returns error when missing access token" do
    ENV["OPENAI_ACCESS_TOKEN"] = nil
    detector = MessageSpamDetector.new(name: "Test", email: "t@t.com", message: "Hi")

    detector.detect
    assert_equal :error, detector.result.status
    assert_equal "Missing OpenAI access token", detector.result.reason
  end

  test "fail-open: errors do not count as spam" do
    OpenAI::Client.any_instance.stubs(:chat).raises(StandardError.new("Timeout"))

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
