if Rails.env.production?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

    config.before_send = lambda do |event, _hint|
      if Current.user
        event.user = {
          id: Current.user.id,
          username: Current.blog&.subdomain
        }
      end

      # Add current blog data if available
      if Current.blog
        event.extra[:blog] = {
          id: Current.blog.id,
          subdomain: Current.blog.subdomain
        }
      end

      event
    end

    # Sampled rather than 100% – every web request and Active Job run counts
    # against the tracing quota, and exhausting it early leaves no traces for
    # the rest of the month.
    config.traces_sample_rate = 0.1

    # Sentry 7 turns structured logging on by default, which ships an event for
    # every Active Record query and Action Controller action.
    config.rails.structured_logging.enabled = false

    # Remove ActionController::BadRequest from sentry-rails' default IGNORE_DEFAULT
    # so unhandled bad requests (not caught by BotErrorFilter) get reported
    config.excluded_exceptions -= [ "ActionController::BadRequest" ]

    # Surpress errors that should result in Sentry noise
    config.excluded_exceptions += [
      "ActiveRecord::RecordNotFound",
      "ActionDispatch::RemoteIp::IpSpoofAttackError",
      "ActionController::TooManyRequests",
      "URI::InvalidURIError",
      "ActionDispatch::Http::MimeNegotiation::InvalidType",
      "Rack::Multipart::EmptyContentError",
      "Encoding::CompatibilityError"
    ]

    # Only enable Sentry in production
    config.enabled_environments = %w[ production ]
  end
end
