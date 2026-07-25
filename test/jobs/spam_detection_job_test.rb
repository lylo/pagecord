require "test_helper"
require "mocha/minitest"

class SpamDetectionJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    SpamDetection.delete_all
    @blog = blogs(:elliot)
    @blog.update_column(:created_at, 1.day.ago)
  end

  test "checks a newly created blog that has never been checked" do
    assert_includes queued_blog_ids, @blog.id
  end

  test "skips a blog that has already been checked" do
    detect!(detected_at: 1.day.ago)

    refute_includes queued_blog_ids, @blog.id
  end

  test "skips a subscribed user" do
    @blog.user.create_subscription!(plan: :monthly, next_billed_at: 1.month.from_now)

    refute_includes queued_blog_ids, @blog.id
  end

  test "rechecks a clean blog that has published since it was checked" do
    settled_blog
    detect!(detected_at: 40.days.ago)
    @blog.posts.create!(content: "new content", published_at: 1.day.ago)

    assert_includes queued_blog_ids, @blog.id
  end

  test "does not recheck a clean blog with nothing published since" do
    settled_blog
    detect!(detected_at: 40.days.ago)
    @blog.posts.create!(content: "old content", published_at: 50.days.ago)

    refute_includes queued_blog_ids, @blog.id
  end

  test "does not recheck a blog an admin has reviewed" do
    settled_blog
    detect!(detected_at: 40.days.ago, reviewed_at: Time.current)
    @blog.posts.create!(content: "new content", published_at: 1.day.ago)

    refute_includes queued_blog_ids, @blog.id
  end

  test "does not recheck a blog already flagged and awaiting review" do
    settled_blog
    detect!(detected_at: 40.days.ago, status: :spam)
    @blog.posts.create!(content: "new content", published_at: 1.day.ago)

    refute_includes queued_blog_ids, @blog.id
  end

  test "does not recheck before the recheck window" do
    settled_blog
    detect!(detected_at: 5.days.ago)
    @blog.posts.create!(content: "new content", published_at: 1.day.ago)

    refute_includes queued_blog_ids, @blog.id
  end

  test "queues a blog only once when it is both new and due a recheck" do
    detect!(detected_at: 40.days.ago)
    @blog.posts.create!(content: "new content", published_at: 1.day.ago)

    assert_equal 1, queued_blog_ids.count(@blog.id)
  end

  private

    # Puts the blog outside the new-signup window, so only recheck rules apply.
    def settled_blog
      @blog.update_column(:created_at, 60.days.ago)
    end

    def detect!(attributes)
      @blog.create_spam_detection!(
        { status: :clean, reason: "fine", model_version: "gpt-4o-mini" }.merge(attributes)
      )
    end

    def queued_blog_ids
      enqueued_jobs.clear
      SpamDetectionJob.perform_now
      enqueued_jobs.select { |job| job["job_class"] == "SpamDetectionCheckJob" }
                   .map { |job| job["arguments"].first }
    end
end
