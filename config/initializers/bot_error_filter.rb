# Middleware to catch common bot errors before they reach error tracking
class BotErrorFilter
  HANDLED_ERRORS = [
    Rack::Multipart::EmptyContentError,
    ActionDispatch::Http::MimeNegotiation::InvalidType,
    URI::InvalidURIError,
    Encoding::CompatibilityError
  ].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue *HANDLED_ERRORS
    [ 400, { "Content-Type" => "text/plain" }, [ "Bad Request\n" ] ]
  end
end

# Insert at the very top of the middleware stack to catch errors before error tracking
Rails.application.config.middleware.insert(0, BotErrorFilter)
