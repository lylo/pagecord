class Blogs::BaseController < ApplicationController
  layout "blog"

  skip_before_action :domain_check
  before_action :load_blog, :validate_user, :enforce_custom_domain, :set_locale

  rescue_from ActiveRecord::RecordNotFound, with: :render_blog_not_found

  protected

  def blog_params
    params.slice(:subdomain, :page, :slug)
  end

  private

    def load_blog
      @blog ||= if custom_domain_request?
        blog_from_custom_domain
      elsif request.subdomain.present? && request.subdomain != "www"
        Blog.includes(:social_links, :avatar_attachment).find_by(subdomain: request.subdomain)
      else
        if blog_params[:subdomain].present?
          Blog.includes(:social_links, :avatar_attachment).find_by(subdomain: blog_params[:subdomain])
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

    def enforce_custom_domain
      redirect_from_default_domain || redirect_to_canonical_custom_domain
    end

    # Redirects requests from the default pagecord.com subdomain to the blog's custom domain
    # Example: joel.pagecord.com/about -> example.com/about
    def redirect_from_default_domain
      return false unless default_domain_request? && @blog.custom_domain.present?

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

    def set_locale
      I18n.locale = @blog&.locale || I18n.default_locale
    end

    def render_blog_not_found
      respond_to do |format|
        format.html { render "blogs/errors/not_found", status: 404 }
        format.any { head :not_found }
      end
    end
end
