class Users::PostsController < ApplicationController
  include Pagy::Backend

  skip_before_action :domain_check      # PostsController can operate with a custom domain

  before_action :load_user, :verification

  def index
    @pagy, @posts = pagy(@user.posts.order(created_at: :desc))

    respond_to do |format|
      format.html
      format.rss { render layout: false }
    end
  end

  def show
    id = Post.from_url_id user_params[:id]
    @post = @user.posts.find(id)

    fresh_when @post
  end

  private

    def load_user
      @user ||= if user_params[:username]
        User.kept.find_by(username: user_params[:username])
      else
        user_from_custom_domain
      end

      redirect_home_with_forbidden if @user.nil?
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
end
