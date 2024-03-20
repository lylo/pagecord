class UsersController < ApplicationController
  layout "home"

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      # TODO go to validation page
      redirect_to user_posts_path(@user.username)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

    def user_params
      params.require(:user).permit(:username, :email)
    end
end
