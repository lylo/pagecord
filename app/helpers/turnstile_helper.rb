module TurnstileHelper
  # Turnstile widgets are restricted to an allowlist of hostnames, so the widget
  # can only be used on the default domain. Custom domains rely on the honeypot,
  # form timing and rate limits instead.
  def turnstile_enabled?
    ENV["TURNSTILE_ENABLED"].present? && default_domain_request?
  end
end
