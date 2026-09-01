class BlogReviewDigestJob < ApplicationJob
  queue_as :default

  def perform
    count = Blog.unreviewed.count

    return if count.zero?

    AdminMailer.blog_review_digest(count).deliver_later
  end
end
