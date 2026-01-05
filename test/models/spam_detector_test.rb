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
      "choices" => [
        {
          "message" => {
            "content" => { classification: "spam", reason: "Obvious spam" }.to_json
          }
        }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    assert_equal "spam", @detector.detect
    assert @detector.spam?
    refute @detector.not_spam?
    refute @detector.uncertain?
    assert_equal "Obvious spam", @detector.reason
  end

  test "detect returns not_spam classification" do
    mock_response = {
      "choices" => [
        {
          "message" => {
            "content" => { classification: "not_spam", reason: "Looks clean" }.to_json
          }
        }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    assert_equal "not_spam", @detector.detect
    assert @detector.not_spam?
    refute @detector.spam?
    refute @detector.uncertain?
    assert_equal "Looks clean", @detector.reason
  end

  test "detect returns uncertain classification" do
    mock_response = {
      "choices" => [
        {
          "message" => {
            "content" => { classification: "uncertain", reason: "Mixed signals" }.to_json
          }
        }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    assert_equal "uncertain", @detector.detect
    assert @detector.uncertain?
    refute @detector.spam?
    refute @detector.not_spam?
    assert_equal "Mixed signals", @detector.reason
  end

  test "detect returns uncertain on json error" do
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

    assert_equal "uncertain", @detector.detect
    assert @detector.uncertain?
    assert_equal "Failed to parse AI response", @detector.reason
  end

  test "detect returns uncertain on api error" do
    OpenAI::Client.any_instance.stubs(:chat).raises(StandardError.new("API Error"))

    assert_equal "uncertain", @detector.detect
    assert @detector.uncertain?
    assert_equal "Detection error", @detector.reason
  end

  test "detect returns uncertain when missing access token" do
    ENV["OPENAI_ACCESS_TOKEN"] = nil
    detector = SpamDetector.new(@blog)

    assert_equal "uncertain", detector.detect
    assert detector.uncertain?
    assert_equal "Missing OpenAI access token", detector.reason
  end

  test "normalizes unknown classification values to uncertain" do
    mock_response = {
      "choices" => [
        {
          "message" => {
            "content" => { classification: "invalid_value", reason: "test" }.to_json
          }
        }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    assert_equal "uncertain", @detector.detect
    assert @detector.uncertain?
  end
end
