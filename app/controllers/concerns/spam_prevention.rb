module SpamPrevention
  extend ActiveSupport::Concern

  included do
    rate_limit to: 5, within: 1.hour, only: [ :create ], name: "spam-prevention-hourly"
    rate_limit to: 1, within: 2.minutes, only: [ :create ], if: :spammer_detected?, name: "spam-prevention-blocked"

    before_action :form_complete_time_check, :honeypot_check, :ip_reputation_check, :suspicious_email_check, only: [ :create ]
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
    timestamp = Rails.application.message_verifier(:spam_prevention).verified(params[:rendered_at])

    unless timestamp
      Rails.logger.warn "Invalid or missing form token. Request blocked."
      fail
      return
    end

    form_complete_time = Time.current.to_i - timestamp

    if form_complete_time < 3.seconds
      Rails.logger.warn "Form completed too quickly. Request blocked."
      fail
    end
  end

  def suspicious_email_check
    email = params.dig(:email_subscriber, :email) || params.dig(:signup, :email) || params[:email]
    return unless email.present?

    local, domain = email.to_s.split("@", 2)
    if domain&.downcase == "gmail.com" && local.count(".") >= 3
      Rails.logger.warn "Dotted Gmail address blocked: #{email}"
      fail
    end
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
