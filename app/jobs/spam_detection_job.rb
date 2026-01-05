class SpamDetectionJob < ApplicationJob
  queue_as :default

  DELAY_BETWEEN_CHECKS = 5.seconds

  def perform
    blogs = Blog.where("blogs.created_at >= ?", 7.days.ago)
                .joins(:user)
                .where(users: { discarded_at: nil })
                .includes(user: :subscription)
                .reject { |blog| blog.user.subscribed? }

    Rails.logger.info "[SpamDetection] Queuing #{blogs.size} blogs for checking"

    blogs.each_with_index do |blog, index|
      SpamDetectionCheckJob.set(wait: index * DELAY_BETWEEN_CHECKS).perform_later(blog.id)
    end
  end
end
