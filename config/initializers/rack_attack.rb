class Rack::Attack
  # Use Rails cache store (Solid Cache in production, memory in dev)
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new if Rails.env.test?

  # --- Safelists ---

  safelist("allow-localhost") do |req|
    ip = req.env["HTTP_X_FORWARDED_FOR"]&.split(",")&.first&.strip || req.ip
    %w[127.0.0.1 ::1].include?(ip)
  end

  # --- Throttles ---

  GENERAL_LIMIT = Rails.env.test? ? 5 : 300
  POST_LIMIT = Rails.env.test? ? 3 : 30

  # Blanket throttle: 300 req/min per IP
  throttle("req/ip", limit: GENERAL_LIMIT, period: 1.minute) do |req|
    req.env["HTTP_X_FORWARDED_FOR"]&.split(",")&.first&.strip || req.ip
  end

  # POST throttle: 30 req/min per IP
  throttle("req/ip/post", limit: POST_LIMIT, period: 1.minute) do |req|
    if req.post?
      req.env["HTTP_X_FORWARDED_FOR"]&.split(",")&.first&.strip || req.ip
    end
  end

  # Existing: protect unauthenticated /app from brute-force
  throttle("req/ip/unauthenticated_exact_app", limit: 5, period: 1.minute) do |req|
    if [ "/app", "/app/" ].include?(req.path) && !req.session["user_id"]
      req.ip
    end
  end

  # --- Response ---

  self.throttled_responder = ->(env) {
    [ 429, { "Content-Type" => "text/plain" }, [ "Rate limit exceeded\n" ] ]
  }

  # --- Instrumentation ---

  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
    req = payload[:request]
    ip = req.env["HTTP_X_FORWARDED_FOR"]&.split(",")&.first&.strip || req.ip
    Rails.logger.warn("[Rack::Attack] Throttled #{req.request_method} #{req.fullpath} from #{ip}")
  end
end
