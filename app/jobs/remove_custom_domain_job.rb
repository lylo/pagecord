class RemoveCustomDomainJob < ApplicationJob
  queue_as :default

  def perform(blog_id, domain)
    if blog = Blog.find(blog_id)
      Rails.logger.info "Removing custom domain #{domain} for blog #{blog.id}"

      if Rails.env.production?
        HatchboxDomainApi.new(blog).remove_domain(domain)
      end
    end
  end
end
