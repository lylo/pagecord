module TurnstileVerification
  extend ActiveSupport::Concern

  include TurnstileHelper

  SITEVERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"
  SITEVERIFY_TIMEOUT = 2

  private

    def turnstile_check
      return if valid_turnstile_token?(params["cf-turnstile-response"])

      Rails.logger.warn "Turnstile check failed. Request blocked."
      reject_submission
    end

    def valid_turnstile_token?(token)
      return true unless turnstile_enabled?
      return false if token.blank?

      response = HTTParty.post(SITEVERIFY_URL, body: {
        secret: ENV["TURNSTILE_SECRET_KEY"],
        response: token,
        remoteip: request.remote_ip
      }, timeout: SITEVERIFY_TIMEOUT)

      # Only a clear verdict blocks. A 5xx, an unparseable body or a network
      # error all mean we can't tell, and Turnstile sits on top of the honeypot,
      # form timing and rate limits, so it must never take signups down with it.
      return true unless response.success? && response.parsed_response.is_a?(Hash)

      response.parsed_response["success"] == true
    rescue StandardError => e
      Rails.logger.error "Turnstile unavailable for #{request.remote_ip}, allowing request: #{e.message}"
      true
    end
end
