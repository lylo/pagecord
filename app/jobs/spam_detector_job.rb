class SpamDetectorJob < ApplicationJob
  queue_as :default

  def perform
    # Check blogs created in the last 7 days, excluding those already discarded
    blogs = Blog.where("blogs.created_at >= ?", 7.days.ago)
                .joins(:user)
                .where(users: { discarded_at: nil })
                .includes(user: :subscription)

    blogs.find_each do |blog|
      next if blog.user.subscribed?

      detector = SpamDetector.new(blog)

      if detector.detect
        handle_spam(blog, detector.reason)
      end
    end
  end

  private

    def handle_spam(blog, reason)
      user = blog.user

      # Discard user with spam flag
      DestroyUserJob.perform_now(user.id, spam: true)

      # Notify admin
      AdminMailer.spam_detected_notification(user.id, reason).deliver_later
    end
end
