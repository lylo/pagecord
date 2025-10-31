# Middleware to redirect trailing slashes to non-trailing slash URLs
class RedirectTrailingSlash
  def initialize(app)
    @app = app
  end

  def call(env)
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
  rescue Rack::Multipart::EmptyContentError
    # Malformed multipart request (bots sending empty body with multipart content-type)
    # Return 400 instead of 500 to avoid error tracking noise
    [ 400, { "Content-Type" => "text/plain" }, [ "Bad Request\n" ] ]
  end
end

# Insert early in the middleware stack to catch requests before routing/caching
Rails.application.config.middleware.insert_before(Rack::Runtime, RedirectTrailingSlash)
