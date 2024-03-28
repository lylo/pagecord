class Users::PostsController < ApplicationController
  include Pagy::Backend

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
      @user = User.kept.find_by(username: user_params[:username])

      redirect_to root_path, alert: "User not found" if @user.nil?
    end

    def user_params
      params.except(:format).permit(:username, :title, :page, :id)
    end

    def verification
      redirect_to root_path if !@user&.verified?
    end
end
