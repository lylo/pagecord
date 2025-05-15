class SignupsController < ApplicationController
  include SpamPrevention, TimezoneTranslation

  layout "sessions"

  def index
    redirect_to new_signup_path
  end

  def new
    @user = User.new(marketing_consent: true)
    @user.build_blog
  end

  def create
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

      redirect_to thanks_signups_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

    def user_params
      raw_params = params.require(:user).permit(:email, :timezone, :marketing_consent, blog_attributes: [ :name ])
      translate_timezone_param(raw_params)
    end

    def translate_timezone_param(params)
      params[:timezone] = active_support_time_zone_from_iana(params[:timezone]) if params[:timezone].present?

      params
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

    def fail
      flash[:error] = "Sorry, that didn't work. Contact support if the problem persists"
      redirect_to new_signup_path
    end
end
