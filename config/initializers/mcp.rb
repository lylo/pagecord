MCP.configure do |config|
  config.exception_reporter = ->(exception, _context) { Sentry.capture_exception(exception) }
end
