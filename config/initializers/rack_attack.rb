class Rack::Attack
  throttle("req/ip/unauthenticated_exact_app", limit: 5, period: 1.minutes) do |req|
    if [ "/app", "/app/" ].include?(req.path) && !req.session["user_id"]
      req.ip
    end
  end

  self.throttled_responder = ->(env) {
    [ 429, { "Content-Type" => "text/plain" }, [ "Rate limit exceeded\n" ] ]
  }
end
