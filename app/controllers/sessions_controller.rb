class SessionsController < ApplicationController
  rate_limit to: 5, within: 5.minutes, only: :create
  rate_limit to: 20, within: 1.minute, only: :new

  layout "sessions"

  def new
    if Current.user.present?
      redirect_to app_root_path
    else
      @user = User.new(blog: Blog.new(subdomain: ""))
      @password_mode = params[:mode] == "password"
    end
  end

  def create
    begin
      if user_params[:password].present?
        create_with_password
      else
        create_with_email
      end
    rescue ActionController::ParameterMissing
      redirect_to login_path, alert: "Invalid request. Please try again."
    end
  end

  def destroy
    sign_out

    redirect_to root_path
  end

  private

    def create_with_password
      user = User.kept.joins(:blog).find_by(blogs: { subdomain: user_params[:subdomain] })

      if user&.authenticate(user_params[:password])
        sign_in user
        redirect_to app_root_path, notice: "Welcome back!"
      else
        flash.now[:alert] = "Invalid subdomain or password"
        @user = User.new(blog: Blog.new(subdomain: user_params[:subdomain]))
        @password_mode = true
        render :new, status: :unprocessable_entity
      end
    end

    def create_with_email
      @user = User.kept.joins(:blog).find_by(
        blogs: { subdomain: user_params[:subdomain] },
        email: user_params[:email]
      )

      if @user.present?
        AccountVerificationMailer.with(user: @user).login.deliver_later
      end

      redirect_to thanks_sessions_path
    end

    def user_params
      permitted = params.require(:user).permit(:subdomain, :email, :password)
      permitted[:subdomain] = permitted[:subdomain].strip.downcase if permitted[:subdomain].present?
      permitted[:email] = permitted[:email].strip.downcase if permitted[:email].present?
      permitted
    end
end
