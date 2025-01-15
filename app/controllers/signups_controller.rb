class SignupsController < ApplicationController
  rate_limit to: 1, within: 5.minutes, only: [ :create ]

  before_action :honeypot_check, :form_complete_time_check, :ip_reputation_check, only: [ :create ]

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

      sign_in @user

      redirect_to thanks_signups_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

    def user_params
      params.require(:user).permit(:email, :marketing_consent, blog_attributes: [ :name ])
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

    def honeypot_check
      unless params[:email_confirmation].blank?
        Rails.logger.warn "Honeypot field completed. Bypassing signup"
        fail
      end
    end

    def form_complete_time_check
      head :unprocessable_entity if params[:rendered_at].blank?

      timestamp = params[:rendered_at].to_i
      form_complete_time = Time.now.to_i - timestamp

      if form_complete_time < 5.seconds
        Rails.logger.warn "Form completed too quickly. Bypassing signup"
        fail
      end
    end

    def ip_reputation_check
      return true unless Rails.env.production?

      unless IpReputation.valid?(request.remote_ip)
        Rails.logger.warn "IP reputation check failed. Bypassing signup"
        fail
      end
    end

    def fail
      flash[:error] = "Sorry, that didn't work. Contact support if the problem persists"
      redirect_to new_signup_path
    end
end
