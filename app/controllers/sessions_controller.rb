class SessionsController < ApplicationController
  rate_limit to: 5, within: 5.minutes, only: :create

  layout "home"

  def new
    if Current.user.present?
      redirect_to app_root_path
    else
      @user = User.new
    end
  end

  def create
    if @user = User.kept.find_by(username: from_params(:username), email: from_params(:email))
      AccountVerificationMailer.with(user: @user).login.deliver_later
    end

    redirect_to thanks_sessions_path
  end

  def destroy
    sign_out

    redirect_to root_path
  end

  private

    def from_params(key)
      if value = user_params[key]
        value.downcase.strip
      end
    end

    def user_params
      params.require(:user).permit(:username, :email)
    end
end
