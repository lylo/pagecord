require "test_helper"
require "mocha/minitest"

class SpamDetectorTest < ActiveSupport::TestCase
  setup do
    @original_token = ENV["OPENAI_ACCESS_TOKEN"]
    ENV["OPENAI_ACCESS_TOKEN"] = "test_token"
    @blog = blogs(:joel)
    @detector = SpamDetector.new(@blog)
  end

  teardown do
    ENV["OPENAI_ACCESS_TOKEN"] = @original_token
  end

  test "detect returns spam classification" do
    mock_response = {
      "model" => "gpt-4o-mini",
      "choices" => [
        {
          "message" => {
            "content" => { classification: "spam", reason: "Obvious spam" }.to_json
          }
        }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    @detector.detect
    assert @detector.spam?
    refute @detector.clean?
    refute @detector.uncertain?
    assert_equal "Obvious spam", @detector.result.reason
    assert_equal :spam, @detector.result.status
  end

  test "detect returns clean classification for not_spam response" do
    mock_response = {
      "model" => "gpt-4o-mini",
      "choices" => [
        {
          "message" => {
            "content" => { classification: "not_spam", reason: "Looks clean" }.to_json
          }
        }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    @detector.detect
    assert @detector.clean?
    refute @detector.spam?
    refute @detector.uncertain?
    assert_equal "Looks clean", @detector.result.reason
    assert_equal :clean, @detector.result.status
  end

  test "detect returns uncertain classification" do
    mock_response = {
      "model" => "gpt-4o-mini",
      "choices" => [
        {
          "message" => {
            "content" => { classification: "uncertain", reason: "Mixed signals" }.to_json
          }
        }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    @detector.detect
    assert @detector.uncertain?
    refute @detector.spam?
    refute @detector.clean?
    assert_equal "Mixed signals", @detector.result.reason
  end

  test "detect returns error on json error" do
    mock_response = {
      "choices" => [
        {
          "message" => {
            "content" => "Not JSON"
          }
        }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    @detector.detect
    assert @detector.error?
    assert_equal "Failed to parse AI response", @detector.result.reason
  end

  test "detect returns error on api error" do
    OpenAI::Client.any_instance.stubs(:chat).raises(StandardError.new("API Error"))

    @detector.detect
    assert @detector.error?
    assert_equal "Detection error", @detector.result.reason
  end

  test "detect returns error when missing access token" do
    ENV["OPENAI_ACCESS_TOKEN"] = nil
    detector = SpamDetector.new(@blog)

    detector.detect
    assert detector.error?
    assert_equal "Missing OpenAI access token", detector.result.reason
  end

  test "normalizes unknown classification values to uncertain" do
    mock_response = {
      "model" => "gpt-4o-mini",
      "choices" => [
        {
          "message" => {
            "content" => { classification: "invalid_value", reason: "test" }.to_json
          }
        }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    @detector.detect
    assert @detector.uncertain?
  end

  test "skips empty blogs" do
    empty_blog = Blog.new(subdomain: "empty", user: users(:joel))
    empty_blog.save(validate: false)

    detector = SpamDetector.new(empty_blog)
    detector.detect

    assert detector.skipped?
    assert_equal "Empty blog - no content to analyze", detector.result.reason
    assert_nil detector.result.model_version
  end

  test "does not skip blog with bio" do
    blog_with_bio = blogs(:joel)
    blog_with_bio.bio = ActionText::Content.new("Test bio")

    detector = SpamDetector.new(blog_with_bio)

    mock_response = {
      "model" => "gpt-4o-mini",
      "choices" => [{ "message" => { "content" => { classification: "not_spam", reason: "Has bio" }.to_json } }]
    }
    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    detector.detect
    refute detector.skipped?
  end

  test "needs_review returns true for spam" do
    mock_response = {
      "model" => "gpt-4o-mini",
      "choices" => [{ "message" => { "content" => { classification: "spam", reason: "Spam" }.to_json } }]
    }
    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    @detector.detect
    assert @detector.needs_review?
  end

  test "needs_review returns true for uncertain" do
    mock_response = {
      "model" => "gpt-4o-mini",
      "choices" => [{ "message" => { "content" => { classification: "uncertain", reason: "Uncertain" }.to_json } }]
    }
    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    @detector.detect
    assert @detector.needs_review?
  end

  test "needs_review returns false for clean" do
    mock_response = {
      "model" => "gpt-4o-mini",
      "choices" => [{ "message" => { "content" => { classification: "not_spam", reason: "Clean" }.to_json } }]
    }
    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    @detector.detect
    refute @detector.needs_review?
  end
end
