class GeneratePostDigestJob < ApplicationJob
  queue_as :default

  def perform(blog_id)
    blog = Blog.kept.find_by(id: blog_id)
    return unless blog

    digest = PostDigest.generate_weekly_digest_for(blog)
    digest&.deliver
  end
end
