class Blogs::DestroyJob < ApplicationJob
  queue_as :default

  # Scoped to discarded so a restore between enqueue and run wins, and so a
  # repeated click on an already-purged blog is a no-op rather than a failure.
  discard_on ActiveRecord::RecordNotFound

  def perform(blog_id)
    blog = Blog.discarded.find(blog_id)

    with_sentry_context(user: blog.user, blog: blog) do
      Rails.logger.info "Permanently deleting blog #{blog.id} (#{blog.subdomain})"
      blog.destroy!
    end
  end
end
