class PostsController < ApplicationController
  include Pagy::Backend

  before_action :load_user, :verification

  def index
    @pagy, @posts = pagy(@user.posts.order(created_at: :desc))
  end

  def show
    @post = @user.posts.find(user_params[:id])
  end

  private

    def load_user
      @user = User.find_by(username:user_params[:username])

      redirect_to root_path, alert: 'User not found' if @user.nil?
    end

    def user_params
      params.permit(:username, :page, :id)
    end

    def verification
      redirect_to root_path if !@user&.verified?
    end
end
