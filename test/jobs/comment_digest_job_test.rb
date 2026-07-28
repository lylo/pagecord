require "test_helper"

class CommentDigestJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    Rails.stubs(:cache).returns(ActiveSupport::Cache::MemoryStore.new)
  end

  test "emails the blogger about comments waiting" do
    assert_enqueued_emails 1 do
      CommentDigestJob.perform_now
    end
  end

  # A backlog you've chosen to sit on shouldn't nag you every day.
  test "sends nothing when no comment arrived today" do
    post_comments(:pending).update_columns(created_at: (CommentDigestJob::WINDOW + 1.hour).ago)

    assert_no_enqueued_emails do
      CommentDigestJob.perform_now
    end
  end

  # Otherwise the count would claim the backlog was smaller than it is.
  test "reports the whole queue once a new comment triggers a digest" do
    posts(:two).comments.create!(name: "Backlog", message: "Waiting since last week")
      .update_columns(created_at: 1.week.ago)
    posts(:two).comments.create!(name: "Arrival", message: "Came in today")

    perform_enqueued_jobs { CommentDigestJob.perform_now }

    body = ActionMailer::Base.deliveries.last.text_part.body.to_s
    assert_match "Backlog", body, "a comment you've sat on still belongs in the count"
    assert_match "Arrival", body
  end

  test "running twice does not enqueue duplicate digests" do
    assert_enqueued_emails 1 do
      2.times { CommentDigestJob.perform_now }
    end
  end

  # Batching by comment rather than blog would split a blog across two digests
  test "sends one email per blog however many comments are waiting" do
    3.times { |i| posts(:two).comments.create!(name: "Reader #{i}", message: "Waiting #{i}") }

    assert_enqueued_emails 1 do
      CommentDigestJob.perform_now
    end
  end

  test "ignores blogs that have turned comments off" do
    blogs(:joel).update!(comments_enabled: false)

    assert_no_enqueued_emails do
      CommentDigestJob.perform_now
    end
  end
end
