require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Set domain configuration for development
  # - Default: localhost (Chrome/Firefox only, Safari doesn't support *.localhost)
  # - APP_DOMAIN=lvh.me: Safari fallback (lvh.me resolves to 127.0.0.1)
  # - APP_DOMAIN=abc.ngrok.io: External access via HTTPS
  app_domain = ENV["APP_DOMAIN"]
  config.x.domain = app_domain || "localhost"
  config.x.cloudflare_image_resizing = false

  case app_domain
  when nil, "localhost"
    default_url_options = { host: "localhost", port: "3000", protocol: "http" }
    # localhost has no TLD, so set tld_length to 0 for subdomain extraction to work
    config.action_dispatch.tld_length = 0
  when "lvh.me"
    # lvh.me is a DNS service that resolves to 127.0.0.1 (Safari fallback)
    default_url_options = { host: "lvh.me", port: "3000", protocol: "http" }
  else
    # External domain (ngrok, etc.) - assumes HTTPS without port
    default_url_options = { host: app_domain, protocol: "https" }
  end
  config.action_controller.default_url_options = default_url_options

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  config.action_mailer.delivery_method = :letter_opener_web
  config.action_mailer.perform_deliveries = true

  config.action_mailer.default_url_options = default_url_options

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true
  config.active_job.queue_adapter = :inline


  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true

  # allow any host in dev
  config.hosts.clear

  # Allow web console from Docker host
  config.web_console.allowed_ips = %w[172.0.0.0/8 10.0.0.0/8 192.168.0.0/16]
end
