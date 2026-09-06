# Middleware to redirect trailing slashes to non-trailing slash URLs
class RedirectTrailingSlash
  def initialize(app)
    @app = app
  end

  def call(env)
    # Reject requests with invalid UTF-8 encoding (typically bot scanners)
    # URL-decode first since percent-encoded bytes may decode to invalid UTF-8
    path_info = env["PATH_INFO"].to_s
    decoded_path = begin
      Rack::Utils.unescape_path(path_info)
    rescue ArgumentError
      path_info
    end
    unless decoded_path.force_encoding("UTF-8").valid_encoding?
      return [ 400, { "Content-Type" => "text/plain" }, [ "Bad Request" ] ]
    end

    # Percent-encode raw non-ASCII bytes so the URL matches what browsers send
    # and request.original_url is plain ASCII
    %w[PATH_INFO QUERY_STRING].each do |key|
      env[key] = URI::RFC2396_PARSER.escape(env[key].to_s.b, /[^[:ascii:]]/n)
    end

    request = Rack::Request.new(env)
    env["ORIGINAL_FULLPATH"] = request.fullpath
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
