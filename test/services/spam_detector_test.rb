require "test_helper"
require "mocha/minitest"

class SpamDetectorTest < ActiveSupport::TestCase
  setup do
    @original_token = ENV["OPENAI_ACCESS_TOKEN"]
    ENV["OPENAI_ACCESS_TOKEN"] = "test_token"
    @blog = blogs(:joel) # Assuming fixtures exist, otherwise I'll create one
    @detector = SpamDetector.new(@blog)
  end

  teardown do
    ENV["OPENAI_ACCESS_TOKEN"] = @original_token
  end

  test "detect returns true when AI reports spam" do
    mock_response = {
      "choices" => [
        {
          "message" => {
            "content" => { spam: true, reason: "Obvious spam" }.to_json
          }
        }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    assert @detector.detect
    assert_equal "Obvious spam", @detector.reason
  end

  test "detect returns false when AI reports ham" do
    mock_response = {
      "choices" => [
        {
          "message" => {
            "content" => { spam: false, reason: "Looks clean" }.to_json
          }
        }
      ]
    }

    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    refute @detector.detect
    assert_equal "Looks clean", @detector.reason
  end

  test "detect returns false on json error" do
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

    refute @detector.detect
    assert_equal "Failed to parse AI response", @detector.reason
  end

  test "detect returns false on api error" do
    OpenAI::Client.any_instance.stubs(:chat).raises(StandardError.new("API Error"))

    refute @detector.detect
    assert_match /Error: API Error/, @detector.reason
  end
end
