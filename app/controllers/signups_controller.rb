class SignupsController < ApplicationController
  include AttributionTrackable, SpamPrevention, TurnstileVerification, TimezoneTranslation

  rate_limit to: 10, within: 1.hour, only: [ :create ], name: "signup-create"
  rate_limit to: 20, within: 1.minute, only: [ :new ], name: "signup-new"

  before_action :turnstile_check, only: [ :create ]

  layout "sessions"

  def index
    redirect_to new_signup_path
  end

  def new
    @user = User.new(marketing_consent: true, signup_referrer: request.referer)
    @user.blogs.build
  end

  def create
    @user = User.new(user_params)

    # New users should get Lexxy if configured
    @user.features = [ "lexxy" ] if ENV["LEXXY_FOR_NEW_USERS"]

    if signup_from_allowed_timezone && @user.save
      attribution = signup_attribution
      session.delete(:signup_attribution)

      AccountVerificationMailer.with(user: @user).verify.deliver_later

      redirect_to thanks_signups_path(attribution)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

    def reject_submission
      flash[:error] = "There's an issue signing you up. If you're using a VPN, try signing up without it. Contact support if the problem persists."
      redirect_to new_signup_path
    end

    def user_params
      @user_params ||= begin
        raw_params = params.require(:user).permit(:email, :timezone, :marketing_consent, :password, :password_confirmation, :signup_referrer, :signup_source_note, blogs_attributes: [ :subdomain ])
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
