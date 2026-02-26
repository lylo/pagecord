class GeneratePostDigestJob < ApplicationJob
  queue_as :default

  def perform(blog_id)
    blog = Blog.find(blog_id)
    digest = PostDigest.generate_weekly_digest_for(blog)
    digest&.deliver
  end
end
