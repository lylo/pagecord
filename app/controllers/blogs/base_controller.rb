class Blogs::BaseController < ApplicationController
  include BlogContentSecurityPolicy
  include Blogs::DomainRedirection
  include Blogs::AccessControl

  layout "blog"

  blog_content_security_policy

  skip_before_action :domain_check

  # The order is load bearing. load_blog sets @blog for everything after it, and
  # the domain redirects run before the access check so a request on the wrong
  # host is moved on rather than shown a password form.
  before_action :load_blog, :validate_user, :enforce_custom_domain, :require_blog_access, :set_locale, :reject_malicious_params

  rescue_from ActiveRecord::RecordNotFound, with: :render_blog_not_found
  rescue_from ActionController::TooManyRequests, with: :render_too_many_requests

  protected

  def blog_params
    params.slice(:subdomain, :page, :slug)
  end

  private

    def load_blog
      @blog ||= if custom_domain_request?
        blog_from_custom_domain
      elsif request.subdomain.present? && request.subdomain != "www"
        Blog.kept.includes(:avatar_attachment).find_by(subdomain: request.subdomain)
      else
        if blog_params[:subdomain].present?
          Blog.kept.includes(:avatar_attachment).find_by(subdomain: blog_params[:subdomain])
        end
      end

      if @blog.nil?
        redirect_to_app_home
      else
        Current.blog = @blog
        @user = @blog.user
      end
    end

    def validate_user
      redirect_to_app_home unless @blog.user&.verified? && @blog.user&.kept?
    end

    def blog_from_custom_domain
      Blog.find_by_domain_with_www_fallback(request.host)
    end

    def set_locale
      I18n.locale = @blog&.locale || I18n.default_locale
    end

    # Rejects null bytes and CRLF in routing params, which are header and log
    # injection attempts. Nested values are left alone so that comment, reply
    # and contact message bodies keep their newlines.
    def reject_malicious_params
      params.each do |key, value|
        next unless value.is_a?(String)
        raise ActiveRecord::RecordNotFound if value.match?(/[\x00\r\n]/)
      end
    end

    # Enable Cloudflare edge caching for *.pagecord.com blog pages. Sets a
    # 12-hour edge TTL with tag-based purging (on post save / blog settings
    # change). Skips the session cookie so Cloudflare doesn't BYPASS the cache.
    # Custom domains are not edge-cached (they route through Caddy, not Cloudflare).
    # No-op unless Cloudflare credentials are configured.
    def set_blog_cache_headers
      return if @blog.password_protected?
      return unless default_domain_request?
      return unless Rails.env.production? && ENV["CLOUDFLARE_ZONE_ID"].present? && ENV["CLOUDFLARE_API_TOKEN"].present?

      response.headers["Cache-Tag"] = @blog.subdomain
      request.session_options[:skip] = true
      expires_in 0, public: true, "s-maxage": 12.hours.to_i, "stale-while-revalidate": 1.hour.to_i
    end

    def render_blog_not_found
      respond_to do |format|
        format.html { render "blogs/errors/not_found", status: 404 }
        format.any { head :not_found }
      end
    end

    def render_too_many_requests
      if request.format.html?
        render "blogs/errors/too_many_requests", status: :too_many_requests
      else
        head :too_many_requests
      end
    end
end
