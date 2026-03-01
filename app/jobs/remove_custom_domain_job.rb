class RemoveCustomDomainJob < ApplicationJob
  queue_as :default

  def perform(blog_id, domain)
    blog = Blog.find(blog_id)

    with_sentry_context(user: blog.user, blog: blog) do
      Rails.logger.info "Removing custom domain #{domain} for blog #{blog.id}"

      if Rails.env.production?
        HatchboxDomainApi.new(blog).remove_domain(domain)
      end
    end
  end
end
