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

  # Anything older belonged to an earlier run, so reporting it again would nag.
  test "ignores comments from before the window" do
    post_comments(:pending).update_columns(created_at: (CommentDigestJob::WINDOW + 1.hour).ago)

    assert_no_enqueued_emails do
      CommentDigestJob.perform_now
    end
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
