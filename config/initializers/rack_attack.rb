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

  GENERAL_LIMIT = Rails.application.config.x.rack_attack[:general_limit]
  POST_LIMIT = Rails.application.config.x.rack_attack[:post_limit]

  # Claude and ChatGPT call /mcp for every user from the same few addresses, so a
  # request with a valid token is left to the per-blog limit in Api::BaseController.
  def self.mcp_authenticated?(req)
    req.env.fetch("pagecord.mcp_authenticated") do
      token = req.env["HTTP_AUTHORIZATION"].to_s[/\ABearer (.+)\z/, 1]
      req.env["pagecord.mcp_authenticated"] = req.path == "/mcp" && token.present? && Blog.find_by_mcp_token(token).present?
    end
  end

  throttle("req/ip", limit: GENERAL_LIMIT, period: 1.minute) do |req|
    req.ip unless mcp_authenticated?(req)
  end

  throttle("req/ip/post", limit: POST_LIMIT, period: 1.minute) do |req|
    req.ip if req.post? && !mcp_authenticated?(req)
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
