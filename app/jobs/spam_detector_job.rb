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
      detector.detect

      if detector.spam? || detector.uncertain?
        notify_admin(blog, detector.classification, detector.reason)
      end
    end
  end

  private

    def notify_admin(blog, classification, reason)
      AdminMailer.spam_detected_notification(blog.user.id, classification, reason).deliver_later
    end
end
