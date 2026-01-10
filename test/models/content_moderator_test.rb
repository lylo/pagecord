require "test_helper"
require "mocha/minitest"

class ContentModeratorTest < ActiveSupport::TestCase
  setup do
    @original_token = ENV["OPENAI_ACCESS_TOKEN"]
    ENV["OPENAI_ACCESS_TOKEN"] = "test_token"
    @post = posts(:one)
    @post.update!(text_summary: "This is test content for moderation")
  end

  teardown do
    ENV["OPENAI_ACCESS_TOKEN"] = @original_token
  end

  test "moderate returns clean for safe content" do
    mock_response = {
      "results" => [
        {
          "category_scores" => { "sexual" => 0.01, "violence" => 0.02, "hate" => 0.005 },
          "flagged" => false
        }
      ],
      "model" => "omni-moderation-2024-09-26"
    }

    OpenAI::Client.any_instance.stubs(:moderations).returns(mock_response)

    moderator = ContentModerator.new(@post)
    moderator.moderate

    assert_equal :clean, moderator.result.status
    assert moderator.clean?
    refute moderator.flagged?
    assert_equal "omni-moderation-2024-09-26", moderator.result.model_version
  end

  test "moderate returns flagged for unsafe content" do
    mock_response = {
      "results" => [
        {
          "category_scores" => { "sexual" => 0.85, "violence" => 0.01, "hate" => 0.02 },
          "flagged" => true
        }
      ],
      "model" => "omni-moderation-2024-09-26"
    }

    OpenAI::Client.any_instance.stubs(:moderations).returns(mock_response)

    moderator = ContentModerator.new(@post)
    moderator.moderate

    assert_equal :flagged, moderator.result.status
    assert moderator.flagged?
    refute moderator.clean?
    assert_equal true, moderator.result.flags["sexual"]
    assert_in_delta 0.85, moderator.result.scores["sexual"], 0.001
  end

  test "moderate aggregates scores from multiple results taking max" do
    mock_response = {
      "results" => [
        { "category_scores" => { "sexual" => 0.3, "violence" => 0.9 }, "flagged" => true },
        { "category_scores" => { "sexual" => 0.85, "violence" => 0.1 }, "flagged" => true }
      ],
      "model" => "omni-moderation-2024-09-26"
    }

    OpenAI::Client.any_instance.stubs(:moderations).returns(mock_response)

    moderator = ContentModerator.new(@post)
    moderator.moderate

    assert_equal :flagged, moderator.result.status
    assert_equal true, moderator.result.flags["sexual"]
    assert_equal true, moderator.result.flags["violence"]
    assert_in_delta 0.85, moderator.result.scores["sexual"], 0.001
    assert_in_delta 0.9, moderator.result.scores["violence"], 0.001
  end

  test "moderate returns error on API failure" do
    OpenAI::Client.any_instance.stubs(:moderations).raises(Faraday::Error.new("Connection failed"))

    moderator = ContentModerator.new(@post)
    moderator.moderate

    assert_equal :error, moderator.result.status
    assert moderator.error?
    assert_equal "Moderation API error", moderator.result.flags[:error]
  end

  test "moderate returns error on bad request" do
    OpenAI::Client.any_instance.stubs(:moderations).raises(Faraday::BadRequestError.new("Invalid input"))

    moderator = ContentModerator.new(@post)
    moderator.moderate

    assert_equal :error, moderator.result.status
    assert_equal "Invalid request to moderation API", moderator.result.flags[:error]
  end

  test "moderate returns error when missing access token" do
    ENV["OPENAI_ACCESS_TOKEN"] = nil
    moderator = ContentModerator.new(@post)
    moderator.moderate

    assert_equal :error, moderator.result.status
    assert_equal "Missing OpenAI access token", moderator.result.flags[:error]
  end

  test "moderate returns error when no content to moderate" do
    @post.stubs(:moderation_text_payload).returns(nil)
    @post.stubs(:moderation_image_payloads).returns([])

    moderator = ContentModerator.new(@post)
    moderator.moderate

    assert_equal :error, moderator.result.status
    assert_equal "No content to moderate", moderator.result.flags[:error]
  end

  test "moderate returns error on empty API response" do
    mock_response = { "results" => [] }

    OpenAI::Client.any_instance.stubs(:moderations).returns(mock_response)

    moderator = ContentModerator.new(@post)
    moderator.moderate

    assert_equal :error, moderator.result.status
    assert_equal "Empty response from API", moderator.result.flags[:error]
  end

  test "score just below threshold returns clean" do
    mock_response = {
      "results" => [
        { "category_scores" => { "violence" => 0.79 } }
      ],
      "model" => "omni-moderation-2024-09-26"
    }

    OpenAI::Client.any_instance.stubs(:moderations).returns(mock_response)

    moderator = ContentModerator.new(@post)
    moderator.moderate

    assert_equal :clean, moderator.result.status
    assert_equal false, moderator.result.flags["violence"]
    assert_in_delta 0.79, moderator.result.scores["violence"], 0.001
  end

  test "score at threshold returns flagged" do
    mock_response = {
      "results" => [
        { "category_scores" => { "violence" => 0.80 } }
      ],
      "model" => "omni-moderation-2024-09-26"
    }

    OpenAI::Client.any_instance.stubs(:moderations).returns(mock_response)

    moderator = ContentModerator.new(@post)
    moderator.moderate

    assert_equal :flagged, moderator.result.status
    assert_equal true, moderator.result.flags["violence"]
  end
end
