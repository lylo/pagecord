class SessionsController < ApplicationController
  layout "home"

  def new
    if Current.user.present?
      redirect_to app_root_path
    else
      @user = User.new
    end
  end

  def create
    if @user = User.kept.find_by(username: user_params[:username]&.downcase, email: user_params[:email]&.downcase)
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
