require "test_helper"
require "mocha/minitest"

class SpamDetectionJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    SpamDetection.delete_all
    @blog = blogs(:elliot)
    @blog.update_column(:created_at, 1.day.ago)
    # Fixture content sits on the CHECK_WINDOW boundary, so each test states its own.
    @blog.all_posts.update_all(published_at: 1.year.ago, updated_at: 1.year.ago)
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

  test "does not recheck a clean blog with nothing changed since" do
    detect!(detected_at: 1.hour.ago)
    untouched_post(published_at: 2.days.ago)

    refute_includes queued_blog_ids, @blog.id
  end

  test "rechecks a clean blog whose existing post was edited since it was checked" do
    post = untouched_post(published_at: 2.days.ago)
    detect!(detected_at: 1.hour.ago)
    post.update!(content: "now with links")

    assert_includes queued_blog_ids, @blog.id
  end

  test "does not recheck a blog an admin has reviewed" do
    detect!(detected_at: 1.hour.ago, reviewed_at: Time.current)
    @blog.posts.create!(content: "new content", published_at: 1.minute.ago)

    refute_includes queued_blog_ids, @blog.id
  end

  test "does not recheck a blog already flagged and awaiting review" do
    detect!(detected_at: 1.hour.ago, status: :spam)
    @blog.posts.create!(content: "new content", published_at: 1.minute.ago)

    refute_includes queued_blog_ids, @blog.id
  end

  test "rechecks a new blog as soon as it publishes after a clean verdict" do
    detect!(detected_at: 1.hour.ago)
    @blog.posts.create!(content: "links now", published_at: 1.minute.ago)

    assert_includes queued_blog_ids, @blog.id
  end

  test "does not recheck a new blog that has published nothing since" do
    detect!(detected_at: 1.hour.ago)

    refute_includes queued_blog_ids, @blog.id
  end

  test "does not recheck a blog past the watch window" do
    settled_blog
    detect!(detected_at: 1.hour.ago)
    @blog.posts.create!(content: "new content", published_at: 1.minute.ago)

    refute_includes queued_blog_ids, @blog.id
  end

  test "checks an unchecked blog that published after the signup window" do
    settled_blog
    @blog.posts.create!(content: "new content", published_at: 1.day.ago)

    assert_includes queued_blog_ids, @blog.id
  end

  test "leaves an unchecked blog alone while it has published nothing recently" do
    settled_blog
    @blog.posts.create!(content: "old content", published_at: 50.days.ago)

    refute_includes queued_blog_ids, @blog.id
  end

  test "checks an unchecked blog whose only recent content is a page" do
    settled_blog
    @blog.pages.create!(title: "Links", content: "new content", published_at: 1.day.ago)

    assert_includes queued_blog_ids, @blog.id
  end

  test "rechecks a clean blog that has published a page since it was checked" do
    detect!(detected_at: 1.hour.ago)
    @blog.pages.create!(title: "Links", content: "new content", published_at: 1.minute.ago)

    assert_includes queued_blog_ids, @blog.id
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

    # Published and left alone since, so updated_at is no fresher than published_at.
    def untouched_post(published_at:)
      @blog.posts.create!(content: "old content", published_at: published_at).tap do |post|
        post.update_columns(updated_at: published_at)
      end
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
