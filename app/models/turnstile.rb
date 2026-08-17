# Verifies Cloudflare Turnstile challenge tokens with the siteverify API.
class Turnstile
  def self.verify?(token, remote_ip:)
    return false if token.blank?

    response = HTTParty.post("https://challenges.cloudflare.com/turnstile/v0/siteverify", body: {
      secret: ENV["TURNSTILE_SECRET_KEY"],
      response: token,
      remoteip: remote_ip
    }, timeout: 2)

    # Only a clear verdict blocks. A 5xx, an unparseable body or a network
    # error all mean we can't tell, and Turnstile sits on top of the honeypot,
    # form timing and rate limits, so it must never take signups down with it.
    return true unless response.success? && response.parsed_response.is_a?(Hash)

    response.parsed_response["success"] == true
  rescue StandardError => e
    Rails.logger.error "Turnstile unavailable for #{remote_ip}, allowing request: #{e.message}"
    true
  end
end
