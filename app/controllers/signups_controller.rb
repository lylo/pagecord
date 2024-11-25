class SignupsController < ApplicationController
  # rate_limit to: 1, within: 5.minutes, only: [ :create ]

  layout "home"

  def index
    redirect_to new_signup_path
  end

  def new
    @user = User.new
  end

  def create
    unless params[:email_confirmation].blank?
      Rails.logger.warn "Honeypot field completed. Bypassing signup"
      head :ok
      return
    end

    if ENV["TURNSTILE_ENABLED"]
      unless valid_turnstile_token?(params["cf-turnstile-response"])
        flash.now[:error] = "Please complete the security check"
        @user = User.new
        render :new and return
      end
    end

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
      params.require(:user).permit(:username, :email, :marketing_consent)
    end

    def valid_turnstile_token?(token)
      return true if Rails.env.test?
      return false if token.blank?

      response = HTTParty.post(
        "https://challenges.cloudflare.com/turnstile/v0/siteverify",
        body: {
          secret: ENV["TURNSTILE_SECRET_KEY"],
          response: token,
          remoteip: request.remote_ip
        }
      )

      response.parsed_response["success"] == true
    rescue HTTParty::Error => e
      Rails.logger.error "Turnstile verification failed: #{e.message}"
      false
    end
end
