class SpamDetectionJob < ApplicationJob
  queue_as :default

  DELAY_BETWEEN_CHECKS = 5.seconds
  RECHECK_AFTER = 30.days

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

    def never_checked
      candidates.where(blogs: { created_at: 7.days.ago..2.hours.ago }, spam_detections: { id: nil })
    end

    # Blogs that passed while they were empty and have published since. Anything an
    # admin has reviewed is left alone, or dismissing a blog would only queue it up
    # again next time.
    def due_for_recheck
      candidates.where(spam_detections: { status: :clean, reviewed_at: nil, detected_at: ...RECHECK_AFTER.ago })
                .where(published_since_detection)
    end

    def published_since_detection
      Post.kept.published.posts
          .where("posts.blog_id = blogs.id")
          .where("posts.published_at > spam_detections.detected_at")
          .arel.exists
    end
end
