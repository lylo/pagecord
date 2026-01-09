class SpamDetectionJob < ApplicationJob
  queue_as :default

  DELAY_BETWEEN_CHECKS = 5.seconds

  def perform
    blogs = Blog.where("blogs.created_at >= ?", 7.days.ago)
                .joins(:user)
                .where(users: { discarded_at: nil })
                .includes(user: :subscription, spam_detection: [])
                .reject { |blog| blog.user.subscribed? || skip_blog?(blog) }

    Rails.logger.info "[SpamDetection] Queuing #{blogs.size} blogs for checking"

    blogs.each_with_index do |blog, index|
      SpamDetectionCheckJob.set(wait: index * DELAY_BETWEEN_CHECKS).perform_later(blog.id)
    end

    # Schedule digest email after all checks complete (with buffer)
    wait_time = (blogs.size * DELAY_BETWEEN_CHECKS) + 5.minutes
    SpamDetectionDigestJob.set(wait: wait_time).perform_later
  end

  private

    def skip_blog?(blog)
      detection = blog.spam_detection
      return false unless detection

      # Skip if blog has an unreviewed spam/uncertain detection
      return true if detection.needs_review?

      # Skip if blog was checked in the last 7 days
      return true if detection.detected_at && detection.detected_at > 7.days.ago

      false
    end
end
