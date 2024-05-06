class Users::PostsController < ApplicationController
  include Pagy::Backend

  skip_before_action :domain_check      # PostsController is available for custom domains

  before_action :load_user, :verification, :enforce_custom_domain

  def index
    @pagy, @posts = pagy(@user.posts.order(published_at: :desc))

    respond_to do |format|
      format.html
      format.rss { render layout: false }
    end
  end

  def show
    id = Post.id_from_url_id(user_params[:id])
    @post = @user.posts.find(id)

    fresh_when @post
  end

  private

    def load_user
      @user ||= if custom_domain_request?
        user_from_custom_domain
      else
        User.kept.find_by(username: user_params[:username]) if user_params[:username].present?
      end

      redirect_home if @user.nil?
    end

    def user_params
      params.except(:format).permit(:username, :title, :page, :id)
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
        request_path = request.path.gsub(/^\/@?#{@user.username}\/?/, '')
        full_url = root_url(host: @user.custom_domain, protocol: request.protocol, port: request.port, only_path: false)
        new_url = "#{full_url}#{request_path}"

        redirect_to new_url, status: :moved_permanently, allow_other_host: true
      end
    end
  end
