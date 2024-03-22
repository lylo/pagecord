if Rails.environment.production?
  Sentry.init do |config|
    config.dsn = 'https://1ec707f4464720240f1c0b02e7ca5693@o4506953782067200.ingest.us.sentry.io/4506953837051904'
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]

    # Set traces_sample_rate to 1.0 to capture 100%
    # of transactions for performance monitoring.
    # We recommend adjusting this value in production.
    config.traces_sample_rate = 1.0
    # or
    config.traces_sampler = lambda do |context|
      true
    end

    # Ignore ActiveRecord::RecordNotFound exceptions
    config.excluded_exceptions += ['ActiveRecord::RecordNotFound']

    # Only enable Sentry in production
    config.enabled_environments = %w[production]
  end
end