class RemoveCustomDomainJob < ApplicationJob
  queue_as :default

  def perform(blog_id, domain)
    blog = Blog.find_by(id: blog_id)
    return unless blog

    with_sentry_context(user: blog.user, blog: blog) do
      Rails.logger.info "Removing custom domain #{domain} for blog #{blog.id}"

      if Rails.env.production?
        CloudflareSaasApi.new(blog).remove_domain(domain)
      end
    end
  end
end
