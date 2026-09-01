class BlogReviewDigestJob < ApplicationJob
  queue_as :default

  def perform
    count = Blog.unreviewed.count
    AdminMailer.blog_review_digest(count).deliver_later if count.positive?
  end
end
