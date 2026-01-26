# Middleware to redirect trailing slashes to non-trailing slash URLs
class RedirectTrailingSlash
  def initialize(app)
    @app = app
  end

  def call(env)
    # Reject requests with invalid UTF-8 encoding (typically bot scanners)
    # URL-decode first since percent-encoded bytes may decode to invalid UTF-8
    path_info = env["PATH_INFO"].to_s
    decoded_path = Rack::Utils.unescape_path(path_info) rescue path_info
    unless decoded_path.force_encoding("UTF-8").valid_encoding?
      return [ 400, { "Content-Type" => "text/plain" }, [ "Bad Request" ] ]
    end

    request = Rack::Request.new(env)
    path = request.path

    # Redirect if path has trailing slash and is not root
    if path.end_with?("/") && path != "/"
      # Use absolute URL for redirect
      target = "#{request.base_url}#{path.chomp('/')}"

      # Preserve query strings (e.g., UTM parameters)
      target += "?#{request.query_string}" unless request.query_string.empty?

      return [ 301, { "Location" => target, "Content-Type" => "text/html" }, [] ]
    end

    @app.call(env)
  end
end

# Insert early in the middleware stack to catch requests before routing/caching
Rails.application.config.middleware.insert_before(Rack::Runtime, RedirectTrailingSlash)
