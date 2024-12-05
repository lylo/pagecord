class AddCustomDomainJob < ApplicationJob
  queue_as :default

  def perform(blog_id, domain)
    blog = Blog.find(blog_id)

    domain_changes_in_the_past_year = blog.custom_domain_changes.where("created_at > ?", 1.year.ago).count

    if domain_changes_in_the_past_year >= 5
      raise "Domain change limit exceeded for blog #{blog.name}"
    else
      Rails.logger.info "Adding custom domain #{domain} for blog #{blog.name}"

      if Rails.env.production?
        HatchboxDomainApi.new(blog).add_domain(domain)
      end
    end
  end
end
