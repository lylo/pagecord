class BlogReviewDigestJob < ApplicationJob
  queue_as :default

  def perform
    count = Blog.unreviewed.where(created_at: ..3.days.ago).count
    AdminMailer.blog_review_digest(count).deliver_later if count.positive?
  end
end
