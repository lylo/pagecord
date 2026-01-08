class SpamDetectionJob < ApplicationJob
  queue_as :default

  DELAY_BETWEEN_CHECKS = 5.seconds

  def perform
    blogs = Blog.where("blogs.created_at >= ?", 7.days.ago)
                .joins(:user)
                .where(users: { discarded_at: nil })
                .includes(user: :subscription, spam_detections: [])
                .reject { |blog| blog.user.subscribed? }
                .reject { |blog| skip_blog?(blog) }

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
      # Skip if blog has an unreviewed spam/uncertain detection
      return true if blog.spam_detections.any?(&:needs_review?)

      # Skip if blog was checked in the last 7 days
      recent_detection = blog.spam_detections.max_by(&:detected_at)
      return true if recent_detection && recent_detection.detected_at > 7.days.ago

      false
    end
end
