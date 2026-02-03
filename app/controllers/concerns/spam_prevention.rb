module SpamPrevention
  extend ActiveSupport::Concern

  DEFAULT_MINIMUM_FORM_COMPLETION_TIME = 3.seconds

  included do
    rate_limit to: 5, within: 1.hour, only: [ :create ], name: "spam-prevention-hourly"
    rate_limit to: 1, within: 2.minutes, only: [ :create ], if: :spammer_detected?, name: "spam-prevention-blocked"

    before_action :form_complete_time_check, :honeypot_check, :ip_reputation_check, only: [ :create ]
  end

  # Override in controllers that need stricter timing (e.g., contact forms)
  def minimum_form_completion_time
    DEFAULT_MINIMUM_FORM_COMPLETION_TIME
  end

  def honeypot_check
    unless params[:email_confirmation].blank?
      Rails.logger.warn "Honeypot field completed. Request blocked."
      fail
    end
  end

  def ip_reputation_check
    # Uncomment to test in development:
    # fail and return

    return true unless Rails.env.production?

    unless IpReputation.valid?(request.remote_ip)
      # Soft fail: log but don't block (too many false positives from CDN IPs)
      Rails.logger.warn "IP reputation check failed for #{request.remote_ip}. Logged but not blocked."
    end
  end

  def form_complete_time_check
    if params[:rendered_at].blank?
      fail
    end

    timestamp = params[:rendered_at].to_i
    form_complete_time = Time.current.to_i - timestamp

    if form_complete_time < minimum_form_completion_time
      Rails.logger.warn "Form completed too quickly. Request blocked."
      fail
    end
  end

  def turnstile_check
    return true unless turnstile_enabled?

    unless valid_turnstile_token?(params["cf-turnstile-response"])
      @turnstile_failed = true
    end
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

  def turnstile_enabled?
    ENV["TURNSTILE_ENABLED"].present?
  end

  def turnstile_failed?
    @turnstile_failed == true
  end

  def fail
    @spammer_detected = true
    head :forbidden
  end

  private

    def spammer_detected?
      @spammer_detected == true
    end
end
