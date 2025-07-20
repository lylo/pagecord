require "active_support/core_ext/integer/time"
require "appsignal"

Rails.application.configure do
  # Prepare the ingress controller used to receive mail
  # config.action_mailbox.ingress = :relay

  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Set domain configuration once
  config.x.domain = ENV.fetch("APP_DOMAIN", "pagecord.com")
  config.x.cloudflare_image_resizing = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false

  config.action_controller.perform_caching = true
  config.action_controller.default_url_options = { host: config.x.domain }
  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/master.key, or an environment
  # key such as config/credentials/production.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from `public/`, relying on NGINX/Apache to do so instead.
  # config.public_file_server.enabled = false

  # Compress CSS using a preprocessor.
  # config.assets.css_compressor = :sass

  # Do not fall back to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  config.asset_host = ENV["ASSET_HOST"]

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = "X-Accel-Redirect" # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :cloudflare
  config.active_storage.delivery_method = :proxy

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Can be used together with config.force_ssl for Strict-Transport-Security and secure cookies.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true
  # see https://github.com/ankane/secure_rails?tab=readme-ov-file
  config.ssl_options = { hsts: { subdomains: true, preload: true, expires: 1.year } }

  config.filter_parameters += [ :email ]

  # LOGGING
  # ---------------------------------

  stdout_logger = ActiveSupport::Logger.new(STDOUT)
  file_logger = ActiveSupport::Logger.new("log/#{Rails.env}.log")
  appsignal_logger = Appsignal::Logger.new("application")

  # Broadcast to all three loggers
  broadcast_logger = ActiveSupport::BroadcastLogger.new(stdout_logger, file_logger, appsignal_logger)
  broadcast_logger.formatter = proc do |severity, time, progname, msg|
    "#{time.iso8601} #{severity} #{msg.strip}\n"
  end

  tagged_logger = ActiveSupport::TaggedLogging.new(broadcast_logger)

  config.log_tags = [
    :request_id,
    ->(request) { "host=#{request.host}" },
    ->(req) { "user_agent=#{req.user_agent}" }
  ]
  config.logger = tagged_logger
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # ---------------------------------

  # Use a different cache store in production.
  config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  config.active_job.queue_adapter = :sidekiq
  # config.active_job.queue_name_prefix = "pagecord_production"

  # Update mailer settings to use config.x.domain
  config.action_mailer.asset_host = "https://#{config.x.domain}"
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: config.x.domain }
  config.action_mailer.delivery_method = :postmark
  config.action_mailer.postmark_settings = {
    api_token: ENV["POSTMARK_API_TOKEN"]
  }

  config.action_mailer.mailpace_settings = {
    api_token: ENV["MAILPACE_API_TOKEN"]
  }

  config.action_mailbox.ingress = :postmark

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end

# Update routes to use config.x.domain
Rails.application.routes.default_url_options = {
  host: Rails.application.config.x.domain,
  protocol: "https"
}
