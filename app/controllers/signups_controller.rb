class SignupsController < ApplicationController
  include SpamPrevention, TimezoneTranslation

  rate_limit to: 3, within: 1.hour, only: [ :create ]
  rate_limit to: 20, within: 1.minute, only: [ :new ]

  layout "sessions"

  def index
    redirect_to new_signup_path
  end

  def new
    @user = User.new(marketing_consent: true)
    @user.build_blog
  end

  def create
    if turnstile_enabled? && !valid_turnstile_token?(params["cf-turnstile-response"])
      flash.now[:error] = "Please complete the security check"
      @user = User.new
      @user.build_blog
      render :new and return
    end

    @user = User.new(user_params)

    # New users should get Lexxy if configured
    @user.blog.features = [ "lexxy" ] if ENV["LEXXY_FOR_NEW_USERS"]

    if signup_from_allowed_timezone && @user.save
      AccountVerificationMailer.with(user: @user).verify.deliver_later

      redirect_to thanks_signups_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

    def fail
      flash[:error] = "There's an issue signing you up. If you're using a VPN, try signing up without it. Contact support if the problem persists."
      redirect_to new_signup_path
    end

    def user_params
      @user_params ||= begin
        raw_params = params.require(:user).permit(:email, :timezone, :marketing_consent, :password, :password_confirmation, blog_attributes: [ :subdomain ])
        translate_timezone_param(raw_params)
      end
    end

    def translate_timezone_param(params)
      params[:timezone] = active_support_time_zone_from_iana(params[:timezone]) if params[:timezone].present?

      params
    end

    def signup_from_allowed_timezone
      banned_timezones = ENV["BANNED_TIMEZONES"]&.split(",")&.map(&:strip) || []
      banned_timezones.exclude?(user_params[:timezone])
    end
end
