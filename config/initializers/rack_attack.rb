class Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new if Rails.env.test?

  # --- Safelists ---

  # `req.ip` walks X-Forwarded-For from the right, skipping trusted proxies
  # (Cloudflare's ranges via the cloudflare-rails gem + RFC1918 + loopback).
  # Never parse X-Forwarded-For directly — the leftmost value is attacker-controlled.
  safelist("allow-localhost") do |req|
    !Rails.env.production? && %w[127.0.0.1 ::1].include?(req.ip)
  end

  # --- Throttles ---

  GENERAL_LIMIT = Rails.env.test? ? 5 : 300
  POST_LIMIT = Rails.env.test? ? 3 : 30

  throttle("req/ip", limit: GENERAL_LIMIT, period: 1.minute) do |req|
    req.ip
  end

  throttle("req/ip/post", limit: POST_LIMIT, period: 1.minute) do |req|
    req.ip if req.post?
  end

  throttle("req/ip/unauthenticated_exact_app", limit: 5, period: 1.minute) do |req|
    req.ip if [ "/app", "/app/" ].include?(req.path) && !req.session["user_id"]
  end

  # --- Response ---

  self.throttled_responder = ->(env) {
    [ 429, { "Content-Type" => "text/plain" }, [ "Rate limit exceeded\n" ] ]
  }

  # --- Instrumentation ---

  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
    req = payload[:request]
    Rails.logger.warn("[Rack::Attack] Throttled #{req.request_method} #{req.fullpath} from #{req.ip}")
  end
end
