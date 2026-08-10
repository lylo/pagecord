if Rails.env.production?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

    config.before_send = lambda do |event, hint|
      if hint[:scope]&.current_hub&.current_scope
        if Current.user
          event.user = {
            id: Current.user.id,
            email: Current.user.email
          }
        end

        # Add current blog data if available
        if Current.blog
          event.extra[:blog] = {
            id: Current.blog.id,
            subdomain: Current.blog.subdomain
          }
        end
      end

      event
    end

    # Sampled rather than 100% – every web request and Active Job run counts
    # against the tracing quota, and exhausting it early leaves no traces for
    # the rest of the month.
    config.traces_sample_rate = 0.1

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
