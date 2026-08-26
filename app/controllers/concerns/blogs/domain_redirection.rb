module Blogs::DomainRedirection
  extend ActiveSupport::Concern

  private

    # Each method returns true once it has issued a redirect, so the first match
    # wins and the rest are skipped.
    def enforce_custom_domain
      redirect_from_lapsed_custom_domain || redirect_from_default_domain || redirect_to_canonical_custom_domain
    end

    def redirect_from_lapsed_custom_domain
      return false unless custom_domain_request? && @blog.custom_domain.present?
      return false if @blog.user.custom_domain_access?

      new_url = "#{request.protocol}#{@blog.subdomain}.#{Rails.application.config.x.domain}#{request.fullpath}"
      redirect_to new_url, status: :moved_permanently, allow_other_host: true
      true
    end

    # Redirects requests from the default pagecord.com subdomain to the blog's custom domain
    # Example: joel.pagecord.com/about -> example.com/about
    def redirect_from_default_domain
      return false unless default_domain_request? && @blog.custom_domain.present?
      return false unless @blog.user.custom_domain_access?

      escaped_subdomain = Regexp.escape(@blog.subdomain)
      request_path = request.path.gsub(/^\/@?#{escaped_subdomain}\/?/, "")
      full_url = root_url(host: @blog.custom_domain, protocol: request.protocol, port: request.port, only_path: false)

      request_path = request_path.sub(/^\//, "") if full_url.end_with?("/")
      new_url = "#{full_url}#{request_path}"

      redirect_to new_url, status: :moved_permanently, allow_other_host: true
      true
    end

    # Redirects requests to the canonical custom domain when accessed via www/non-www variant
    # Example: www.example.com/about -> example.com/about (if blog.custom_domain is "example.com")
    def redirect_to_canonical_custom_domain
      return false unless custom_domain_request? && @blog.custom_domain.present?
      return false if @blog.custom_domain == request.host

      new_url = "#{request.protocol}#{@blog.custom_domain}#{request.fullpath}"
      redirect_to new_url, status: :moved_permanently, allow_other_host: true
      true
    end
end
