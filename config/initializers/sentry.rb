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

    # Set traces_sample_rate to 1.0 to capture 100%
    # of transactions for performance monitoring.
    # We recommend adjusting this value in production.
    config.traces_sample_rate = 1.0
    # or
    config.traces_sampler = lambda do |context|
      true
    end

    # Surpress errors that should result in Sentry noise
    config.excluded_exceptions += [
      "ActiveRecord::RecordNotFound",
      "ActionDispatch::RemoteIp::IpSpoofAttackError"
    ]

    # Only enable Sentry in production
    config.enabled_environments = %w[ production ]
  end
end
