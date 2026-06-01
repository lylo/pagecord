class RefreshCloudflareCustomHostnamesJob < ApplicationJob
  queue_as :default

  MAX_ATTEMPTS = 30

  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(blog_id, domain, attempt = 1)
    blog = Blog.find_by(id: blog_id)
    return unless Rails.env.production?
    return unless blog&.custom_domain == domain

    refreshed_hostnames = CloudflareSaasApi.new(blog).refresh_domain_validation(domain)
    return if refreshed_hostnames.blank? || attempt >= MAX_ATTEMPTS

    self.class
      .set(wait: retry_wait(attempt))
      .perform_later(blog_id, domain, attempt + 1)
  end

  private

    def retry_wait(attempt)
      attempt < 6 ? 10.minutes : 1.hour
    end
end
