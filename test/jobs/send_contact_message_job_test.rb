require "test_helper"
require "mocha/minitest"

class SendContactMessageJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @original_detection = ENV["EMAIL_SPAM_DETECTION"]
    @blog = blogs(:joel)
    @contact_message = Blog::ContactMessage.create!(
      blog: @blog,
      name: "Test User",
      email: "sender@example.com",
      message: "Hello, this is a test message."
    )
  end

  teardown do
    ENV["EMAIL_SPAM_DETECTION"] = @original_detection
  end

  test "sends email and deletes contact message" do
    assert_difference "Blog::ContactMessage.count", -1 do
      assert_emails 1 do
        SendContactMessageJob.perform_now(@contact_message.id)
      end
    end

    assert_nil Blog::ContactMessage.find_by(id: @contact_message.id)
  end

  test "does nothing if contact message not found" do
    @contact_message.destroy

    assert_no_difference "Blog::ContactMessage.count" do
      assert_emails 0 do
        SendContactMessageJob.perform_now(@contact_message.id)
      end
    end
  end

  test "blocks spam and destroys message without sending" do
    ENV["EMAIL_SPAM_DETECTION"] = "true"
    spam_result = MessageSpamDetector::Result.new(status: :spam, reason: "SEO solicitation")
    MessageSpamDetector.any_instance.stubs(:detect).returns(spam_result)
    MessageSpamDetector.any_instance.stubs(:result).returns(spam_result)
    MessageSpamDetector.any_instance.stubs(:spam?).returns(true)

    assert_difference "Blog::ContactMessage.count", -1 do
      assert_emails 0 do
        SendContactMessageJob.perform_now(@contact_message.id)
      end
    end
  end

  test "sends email on detection error (fail-open)" do
    ENV["EMAIL_SPAM_DETECTION"] = "true"
    error_result = MessageSpamDetector::Result.new(status: :error, reason: "Detection error")
    MessageSpamDetector.any_instance.stubs(:detect).returns(error_result)
    MessageSpamDetector.any_instance.stubs(:result).returns(error_result)
    MessageSpamDetector.any_instance.stubs(:spam?).returns(false)

    assert_emails 1 do
      SendContactMessageJob.perform_now(@contact_message.id)
    end
  end

  test "skips spam check when EMAIL_SPAM_DETECTION is not set" do
    ENV["EMAIL_SPAM_DETECTION"] = nil

    assert_emails 1 do
      SendContactMessageJob.perform_now(@contact_message.id)
    end
  end
end
