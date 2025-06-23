require "test_helper"

class SendPostReplyJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "should destroy reply after emailing reply" do
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
end
