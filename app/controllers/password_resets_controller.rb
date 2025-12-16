class PasswordResetsController < ApplicationController
  include SpamPrevention

  skip_before_action :authenticate, :domain_check
  before_action :find_access_request, only: [ :edit, :update ]

  layout "sessions"

  def new
    @user = User.new(blog: Blog.new)
  end

  def create
    user = User.kept.joins(:blog).find_by(
      blogs: { subdomain: user_params[:subdomain] },
      email: user_params[:email]
    )

    PasswordResetMailer.with(user: user).reset.deliver_later if user

    redirect_to thanks_password_resets_path
  end

  def edit
  end

  def update
    if @user.update(password_params)
      @access_request.accept!
      sign_in @user
      redirect_to app_root_path, notice: "Password updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

    def fail
      @spammer_detected = true
      redirect_to new_password_reset_path, alert: "Something went wrong, please try again or contact support if the problem persists"
    end

    def find_access_request
      @access_request = AccessRequest.password_reset.active.pending.find_by(token_digest: params[:token])

      unless @access_request
        redirect_to login_path, alert: "Invalid or expired reset link"
        return
      end

      @user = @access_request.user
    end

    def user_params
      params.require(:user).permit(:subdomain, :email)
        .transform_values { |v| v.strip.downcase }
    end

    def password_params
      params.require(:user).permit(:password, :password_confirmation)
    end
end
