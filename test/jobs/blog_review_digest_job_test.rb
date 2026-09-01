require "test_helper"

class BlogReviewDigestJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "emails the count of blogs waiting for review" do
    blogs(:elliot).update!(reviewed_at: nil)

    assert_enqueued_email_with AdminMailer, :blog_review_digest, args: [ Blog.unreviewed.count ] do
      BlogReviewDigestJob.perform_now
    end
  end

  test "stays quiet when nothing is waiting" do
    Blog.update_all(reviewed_at: Time.current)

    assert_no_enqueued_emails do
      BlogReviewDigestJob.perform_now
    end
  end
end
