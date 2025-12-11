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
    # Proactively reject malformed multipart requests before they cause errors
    if malformed_multipart_request?(env)
      return [ 400, { "Content-Type" => "text/plain" }, [ "Bad Request\n" ] ]
    end

    @app.call(env)
  rescue *HANDLED_ERRORS
    [ 400, { "Content-Type" => "text/plain" }, [ "Bad Request\n" ] ]
  rescue ActionController::BadRequest => e
    raise unless HANDLED_ERRORS.any? { |error_class| e.cause.is_a?(error_class) }
    [ 400, { "Content-Type" => "text/plain" }, [ "Bad Request\n" ] ]
  end

  private

    def malformed_multipart_request?(env)
      content_type = env["CONTENT_TYPE"]
      return false unless content_type&.include?("multipart/form-data")

      # Check if body is empty or missing when multipart content-type is declared
      content_length = env["CONTENT_LENGTH"].to_i
      return true if content_length == 0

      # Check if boundary is missing
      return true unless content_type.include?("boundary=")

      false
    end
end

# Insert at the very top of the middleware stack to catch errors before error tracking
Rails.application.config.middleware.insert(0, BotErrorFilter)
