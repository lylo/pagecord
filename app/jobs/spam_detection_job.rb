class SpamDetectionJob < ApplicationJob
  queue_as :default

  DELAY_BETWEEN_CHECKS = 5.seconds
  WATCH_WINDOW = 30.days
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
      Post.kept.published
          .where("posts.blog_id = blogs.id")
          .where(published_at: CHECK_WINDOW.ago..)
          .arel.exists
    end

    # A clean verdict is easiest to game while a blog is new: post something
    # harmless, wait for it to land, then add the links. So a blog is rechecked on
    # every change through its first month and then left alone – spam earns its
    # keep from indexed backlinks, so it goes up early or not at all. Anything an
    # admin has reviewed is skipped, or dismissing a blog would only queue it up
    # again next time.
    def due_for_recheck
      candidates.where(spam_detections: { status: :clean, reviewed_at: nil })
                .where(blogs: { created_at: WATCH_WINDOW.ago.. })
                .where(changed_since_detection)
    end

    # Edits count, not just new posts: published_at never moves once content is
    # live, so a blog that passed clean and then had the links added to an existing
    # post would never be looked at again. Action Text touches the post on every
    # body change, so updated_at catches that.
    def changed_since_detection
      Post.kept.published
          .where("posts.blog_id = blogs.id")
          .where("GREATEST(posts.published_at, posts.updated_at) > spam_detections.detected_at")
          .arel.exists
    end
end
