require "test_helper"

class BlogReviewDigestJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "counts only blogs that have waited three days" do
    blogs(:elliot).update_columns(reviewed_at: nil, created_at: 4.days.ago)
    blogs(:vivian).update_columns(reviewed_at: nil, created_at: 2.days.ago)

    assert_enqueued_email_with AdminMailer, :blog_review_digest, args: [ 1 ] do
      BlogReviewDigestJob.perform_now
    end
  end

  test "stays quiet when only newer blogs are waiting" do
    blogs(:vivian).update_columns(reviewed_at: nil, created_at: 2.days.ago)

    assert_no_enqueued_emails do
      BlogReviewDigestJob.perform_now
    end
  end

  test "stays quiet when the waiting blogs are blank" do
    blogs(:unengaged).update_columns(created_at: 4.days.ago)

    assert_no_enqueued_emails do
      BlogReviewDigestJob.perform_now
    end
  end
end
