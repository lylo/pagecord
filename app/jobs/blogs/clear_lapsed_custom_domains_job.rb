class Blogs::ClearLapsedCustomDomainsJob < ApplicationJob
  queue_as :default

  def perform
    Blog.kept.where.not(custom_domain: nil).find_each do |blog|
      next if blog.user.custom_domain_access?

      domain = blog.custom_domain
      blog.update!(custom_domain: nil)
      RemoveCustomDomainJob.perform_later(blog.id, domain) unless ENV["ON_DEMAND_TLS"].present?

      Rails.logger.info "Cleared lapsed custom domain #{domain} for blog #{blog.id}"
    end
  end
end
