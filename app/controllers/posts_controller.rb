class PostsController < ApplicationController
  include Pagy::Backend

  before_action :load_user, :verification

  def index
    @pagy, @posts =  pagy(@user.posts)
  end

  def show
    @post = @user.posts.find(params[:id])
  end

  private

    def load_user
      @user = User.find_by(username:user_params[:username])

      redirect_to root_path, alert: 'User not found' if @user.nil?
    end

    def user_params
      params.permit(:username, :page)
    end

    def verification
      redirect_to root_path if !@user&.verified?
    end
end
