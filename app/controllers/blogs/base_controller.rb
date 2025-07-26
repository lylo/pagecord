class Blogs::BaseController < ApplicationController
  skip_before_action :domain_check
  before_action :load_blog, :validate_user, :enforce_custom_domain, :set_locale

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
      redirect_to root_path unless @blog.user&.verified? && @blog.user&.kept?
    end

    def blog_from_custom_domain
      Blog.find_by(custom_domain: request.host)
    end

    def enforce_custom_domain
      if default_domain_request? && @blog.custom_domain.present?
        escaped_subdomain = Regexp.escape(@blog.subdomain)
        request_path = request.path.gsub(/^\/@?#{escaped_subdomain}\/?/, "")
        full_url = root_url(host: @blog.custom_domain, protocol: request.protocol, port: request.port, only_path: false)

        request_path = request_path.sub(/^\//, "") if full_url.end_with?("/")
        new_url = "#{full_url}#{request_path}"

        redirect_to new_url, status: :moved_permanently, allow_other_host: true
      end
    end

    def set_locale
      I18n.locale = @blog&.locale || I18n.default_locale
    end
end
