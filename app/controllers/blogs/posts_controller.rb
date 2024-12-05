class Blogs::PostsController < ApplicationController
  include Pagy::Backend
  rescue_from Pagy::OverflowError, with: :redirect_to_last_page

  skip_before_action :domain_check
  before_action :load_blog, :verification, :enforce_custom_domain

  def index
    @pagy, @posts = pagy(@blog.posts.order(published_at: :desc))

    respond_to do |format|
      format.html
      format.rss { render layout: false }
    end
  end

  def show
    @post = @blog.posts.find_by!(token: user_params[:token])

    fresh_when @post
  end

  private

    def load_blog
      @blog ||= if custom_domain_request?
        blog_from_custom_domain
      else
        if user_params[:username].present?
          User.kept.joins(:blog).find_by(username: user_params[:username]).try(:blog)
        end
      end

      if @blog.nil?
        redirect_to_app_home
      end
    end

    def user_params
      params.permit(:username, :page, :token)
    end

    def verification
      redirect_to root_path unless @blog.user&.verified?
    end

    def blog_from_custom_domain
      User.kept.joins(:blog).find_by(blog: { custom_domain: request.host }).try(:blog)
    end

    def enforce_custom_domain
      if default_domain_request? && @blog.custom_domain.present?
        escaped_username = Regexp.escape(@blog.user.username)
        request_path = request.path.gsub(/^\/@?#{escaped_username}\/?/, "")
        full_url = root_url(host: @blog.custom_domain, protocol: request.protocol, port: request.port, only_path: false)
        new_url = "#{full_url}#{request_path}"

        redirect_to new_url, status: :moved_permanently, allow_other_host: true
      end
    end

    def redirect_to_last_page(exception)
      redirect_to url_for(page: exception.pagy.last)
    end
end
