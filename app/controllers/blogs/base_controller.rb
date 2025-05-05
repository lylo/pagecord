class Blogs::BaseController < ApplicationController
  skip_before_action :domain_check, :authenticate

  before_action :load_blog, :validate_user, :enforce_custom_domain

  protected

  def blog_params
    params.slice(:name, :page, :title, :token)
  end

  private

    def load_blog
      @blog ||= if custom_domain_request?
        blog_from_custom_domain
      else
        if blog_params[:name].present?
          Blog.includes(:social_links, :avatar_attachment).find_by(name: blog_params[:name])
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
        escaped_name = Regexp.escape(@blog.name)
        request_path = request.path.gsub(/^\/@?#{escaped_name}\/?/, "")
        full_url = root_url(host: @blog.custom_domain, protocol: request.protocol, port: request.port, only_path: false)
        new_url = "#{full_url}#{request_path}"

        redirect_to new_url, status: :moved_permanently, allow_other_host: true
      end
    end
end
