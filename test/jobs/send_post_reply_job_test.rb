require "test_helper"
require "mocha/minitest"

class SendPostReplyJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @original_detection = ENV["EMAIL_SPAM_DETECTION"]
  end

  teardown do
    ENV["EMAIL_SPAM_DETECTION"] = @original_detection
  end

  test "sends email and destroys reply" do
    reply = post_replies(:test)

    assert_emails 1 do
      SendPostReplyJob.perform_now(reply.id)
    end

    assert_not Post::Reply.exists?(reply.id)
  end

  test "should handle missing reply gracefully" do
    assert_nothing_raised do
      SendPostReplyJob.perform_now(999999)
    end
  end

  test "blocks spam and destroys reply without sending" do
    reply = post_replies(:test)

    ENV["EMAIL_SPAM_DETECTION"] = "true"
    MessageSpamDetector.any_instance.stubs(:detect).returns(nil)
    MessageSpamDetector.any_instance.stubs(:spam?).returns(true)

    assert_emails 0 do
      SendPostReplyJob.perform_now(reply.id)
    end

    assert_not Post::Reply.exists?(reply.id)
  end

  test "sends email on detection error (fail-open)" do
    reply = post_replies(:test)

    ENV["EMAIL_SPAM_DETECTION"] = "true"
    MessageSpamDetector.any_instance.stubs(:detect).returns(nil)
    MessageSpamDetector.any_instance.stubs(:spam?).returns(false)

    assert_emails 1 do
      SendPostReplyJob.perform_now(reply.id)
    end
  end

  test "skips spam check when EMAIL_SPAM_DETECTION is not set" do
    ENV["EMAIL_SPAM_DETECTION"] = nil
    reply = post_replies(:test)

    assert_emails 1 do
      SendPostReplyJob.perform_now(reply.id)
    end
  end
end
