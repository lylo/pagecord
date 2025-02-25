require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Pagecord
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[ assets tasks ])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras"

    config.active_support.to_time_preserves_timezone = :zone

    config.active_record.automatically_invert_plural_associations = true

    config.filter_parameters += [ :RawEmail, :Attachments, :HtmlBody, :TextBody, :Headers ]

    Rails::HTML5::Sanitizer.safe_list_sanitizer.allowed_tags += [ "s", "u", "video", "source" ]
    Rails::HTML5::Sanitizer.safe_list_sanitizer.allowed_attributes += [ "style", "controls", "poster", "playsinline" ]

    config.exceptions_app = self.routes

    # ignore mismatches between HTTP_CLIENT_IP and HTTP_X_FORWARDED_FOR
    # config.action_dispatch.ip_spoofing_check = false

    config.x.domain = ENV.fetch("APP_DOMAIN", "pagecord.com")
  end
end
