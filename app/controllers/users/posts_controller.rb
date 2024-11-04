class Users::PostsController < ApplicationController
  include Pagy::Backend

  # TODO consider separate base controller for public pages
  skip_before_action :domain_check

  rescue_from Pagy::OverflowError, with: :redirect_to_last_page

  before_action :load_user, :verification, :enforce_custom_domain

  def index
    @pagy, @posts = pagy(@user.posts.order(published_at: :desc))

    respond_to do |format|
      format.html
      format.rss { render layout: false }
    end
  end

  def show
    @post = @user.posts.find_by!(token: user_params[:token])

    fresh_when @post
  end

  private

    def load_user
      @user ||= if custom_domain_request?
        user_from_custom_domain
      else
        User.kept.find_by(username: user_params[:username]) if user_params[:username].present?
      end

      redirect_home if @user.nil? || @user&.free_trial_expired?
    end

    def user_params
      params.except(:format).permit(:username, :title, :page, :id, :token)
    end

    def verification
      redirect_to root_path if !@user&.verified?
    end

    def user_from_custom_domain
      if custom_domain_request?
        User.kept.find_by(custom_domain: request.host)
      end
    end

    def enforce_custom_domain
      if default_domain_request? && @user.custom_domain.present?
        escaped_username = Regexp.escape(@user.username)
        request_path = request.path.gsub(/^\/@?#{escaped_username}\/?/, "")
        full_url = root_url(host: @user.custom_domain, protocol: request.protocol, port: request.port, only_path: false)
        new_url = "#{full_url}#{request_path}"

        redirect_to new_url, status: :moved_permanently, allow_other_host: true
      end
    end

    def redirect_to_last_page(exception)
      redirect_to url_for(page: exception.pagy.last)
    end
end
