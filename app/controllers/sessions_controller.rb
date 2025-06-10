class SessionsController < ApplicationController
  rate_limit to: 5, within: 5.minutes, only: :create
  rate_limit to: 5, within: 1.minute, only: :new

  layout "sessions"

  def new
    if Current.user.present?
      redirect_to app_root_path
    else
      @user = User.new(blog: Blog.new(subdomain: ""))
    end
  end

  def create
    begin
      @user = User.kept.joins(:blog).find_by(
        blogs: {
          subdomain: user_params[:subdomain]
        },
        email: user_params[:email]
      )

      if @user.present?
        AccountVerificationMailer.with(user: @user).login.deliver_later
      end

      redirect_to thanks_sessions_path
    rescue ActionController::ParameterMissing
      redirect_to login_path, alert: "Invalid request. Please try again."
    end
  end

  def destroy
    sign_out

    redirect_to root_path
  end

  private

    def user_params
      params.require(:user).permit(:subdomain, :email)
        .transform_values { |v| v.strip.downcase }
    end
end
