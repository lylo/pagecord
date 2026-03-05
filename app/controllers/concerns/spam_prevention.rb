module SpamPrevention
  extend ActiveSupport::Concern

  DEFAULT_MINIMUM_FORM_COMPLETION_TIME = 3.seconds

  included do
    before_action :form_complete_time_check, :honeypot_check, :ip_reputation_check, :suspicious_email_check, only: [ :create ]
  end

  # Override in controllers that need stricter timing (e.g., contact forms)
  def minimum_form_completion_time
    DEFAULT_MINIMUM_FORM_COMPLETION_TIME
  end

  def honeypot_check
    if params[:email_confirmation].present?
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
    timestamp = Rails.application.message_verifier(:spam_prevention).verified(params[:rendered_at])

    if timestamp.nil?
      Rails.logger.warn "Invalid or missing form token. Request blocked."
      return fail
    end

    if (Time.current.to_i - timestamp) < minimum_form_completion_time
      Rails.logger.warn "Form completed too quickly. Request blocked."
      fail
    end
  end

  def suspicious_email_check
    email = params.dig(:email_subscriber, :email) || params.dig(:signup, :email) || params[:email]
    return if email.blank?

    local, domain = email.split("@", 2)
    if domain&.downcase == "gmail.com" && local.count(".") >= 3
      Rails.logger.warn "Dotted Gmail address blocked: #{email}"
      fail
    end
  end

  def turnstile_check
    return true unless turnstile_enabled?
    fail unless valid_turnstile_token?(params["cf-turnstile-response"])
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
    ENV["TURNSTILE_ENABLED"].present? && default_domain_request?
  end

  def fail
    @spammer_detected = true
    head :forbidden
  end
end
