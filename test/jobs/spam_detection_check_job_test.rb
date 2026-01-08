require "test_helper"
require "mocha/minitest"

class SpamDetectionCheckJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  setup do
    @original_token = ENV["OPENAI_ACCESS_TOKEN"]
    ENV["OPENAI_ACCESS_TOKEN"] = "test_token"
    @blog = blogs(:joel)
  end

  teardown do
    ENV["OPENAI_ACCESS_TOKEN"] = @original_token
  end

  test "saves spam detection result to database" do
    mock_response = {
      "model" => "gpt-4o-mini",
      "choices" => [
        {
          "message" => {
            "content" => { classification: "spam", reason: "Spam content" }.to_json
          }
        }
      ]
    }
    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    assert_difference "@blog.spam_detections.count", 1 do
      SpamDetectionCheckJob.perform_now(@blog.id)
    end

    detection = @blog.spam_detections.last
    assert detection.spam?
    assert_equal "Spam content", detection.reason
    assert_equal "gpt-4o-mini", detection.model_version
    assert_not_nil detection.detected_at
  end

  test "saves clean result to database" do
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

    SpamDetectionCheckJob.perform_now(@blog.id)

    detection = @blog.spam_detections.last
    assert detection.clean?
  end

  test "does not send individual email" do
    mock_response = {
      "model" => "gpt-4o-mini",
      "choices" => [
        {
          "message" => {
            "content" => { classification: "spam", reason: "Spam" }.to_json
          }
        }
      ]
    }
    OpenAI::Client.any_instance.stubs(:chat).returns(mock_response)

    assert_no_enqueued_emails do
      SpamDetectionCheckJob.perform_now(@blog.id)
    end
  end

  test "handles non-existent blog gracefully" do
    assert_nothing_raised do
      SpamDetectionCheckJob.perform_now(-1)
    end
  end

  test "saves skipped result for empty blog" do
    empty_blog = Blog.new(subdomain: "emptyblog#{SecureRandom.hex(4)}", user: users(:joel))
    empty_blog.save(validate: false)

    assert_difference "SpamDetection.count", 1 do
      SpamDetectionCheckJob.perform_now(empty_blog.id)
    end

    detection = empty_blog.spam_detections.last
    assert detection.skipped?
  end
end
