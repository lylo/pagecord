class SessionsController < ApplicationController
  layout "home"

  def new
    @user = User.new
  end

  def create
    if @user = User.find_by(username: user_params[:username]&.downcase, email: user_params[:email]&.downcase)
      AccountVerificationMailer.with(user: @user).login.deliver_later
    end

    redirect_to thanks_sessions_path
  end

  def destroy
    sign_out

    redirect_to root_path
  end

  private

    def user_params
      params.require(:user).permit(:username, :email)
    end
end
