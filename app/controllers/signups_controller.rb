class SignupsController < ApplicationController
  layout "home"

  def index
    redirect_to new_signup_path
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      AccountVerificationMailer.with(user: @user).verify.deliver_later

      sign_in @user

      redirect_to thanks_signups_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

    def user_params
      params.require(:user).permit(:username, :email)
    end
end
