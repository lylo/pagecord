class SessionsController < ApplicationController
  layout "home"

  def new
  end

  def create
    if @user = User.find_by(username: params[:username], email: params[:email])
      AccountVerificationMailer.with(user: @user).verify.deliver_later
    end

    redirect_to thanks_sessions_path
  end

  def destroy
    sign_out

    redirect_to root_path
  end
end
