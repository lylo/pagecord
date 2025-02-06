if Rails.env.production?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

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
