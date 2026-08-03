class SpamDetectionJob < ApplicationJob
  queue_as :default

  DELAY_BETWEEN_CHECKS = 5.seconds
  RECHECK_AFTER = 30.days
  CHECK_WINDOW = 7.days

  def perform
    blogs = Blog.where(id: never_checked).or(Blog.where(id: due_for_recheck))
                .includes(user: :subscription).reject { |blog| blog.user.subscribed? }

    Rails.logger.info "[SpamDetection] Checking #{blogs.size} blogs"

    blogs.each_with_index do |blog, index|
      SpamDetectionCheckJob.set(wait: index * DELAY_BETWEEN_CHECKS).perform_later(blog.id)
    end
  end

  private

    def candidates
      Blog.kept.joins(:user).where(users: { discarded_at: nil }).left_joins(:spam_detection)
    end

    # New signups, plus blogs that stayed empty past the signup window and have
    # published since. An empty blog is skipped without saving a detection, so it
    # sits here unchecked until there is something to judge. Bounded by recent
    # publishing rather than any post at all, or the first run would sweep up
    # every blog that predates this job.
    def never_checked
      candidates.where(blogs: { created_at: ..2.hours.ago }, spam_detections: { id: nil })
                .where(created_recently.or(published_recently))
    end

    def created_recently
      Blog.arel_table[:created_at].gteq(CHECK_WINDOW.ago)
    end

    def published_recently
      Post.kept.published.posts
          .where("posts.blog_id = blogs.id")
          .where(published_at: CHECK_WINDOW.ago..)
          .arel.exists
    end

    # Blogs that passed while they were empty and have published since. Anything an
    # admin has reviewed is left alone, or dismissing a blog would only queue it up
    # again next time.
    #
    # A clean verdict is easiest to game while a blog is new: post something
    # harmless, wait for it to land, then add the links. So a new blog is rechecked
    # as soon as it publishes again, and only settled ones wait out the month.
    def due_for_recheck
      candidates.where(spam_detections: { status: :clean, reviewed_at: nil })
                .where(published_since_detection)
                .where(created_recently.or(detected_long_ago))
    end

    def detected_long_ago
      SpamDetection.arel_table[:detected_at].lt(RECHECK_AFTER.ago)
    end

    def published_since_detection
      Post.kept.published.posts
          .where("posts.blog_id = blogs.id")
          .where("posts.published_at > spam_detections.detected_at")
          .arel.exists
    end
end
