require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Pagecord
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[ assets tasks middleware ])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    config.active_storage.variant_processor = :vips

    config.active_record.automatically_invert_plural_associations = true

    # Helpers live in named modules, so skip the empty per-controller stubs.
    config.generators do |g|
      g.helper false
    end

    # Configure available locales
    config.i18n.available_locales = [ :en, :id, :de, :es, :fr, :nl, :pl, :pt, :fi, :ja, :el ]
    config.i18n.default_locale = :en

    config.filter_parameters += [ :RawEmail, :Attachments, :HtmlBody, :TextBody, :Headers ]

    config.exceptions_app = self.routes

    # Cloudflare fronts the app and cloudflare-rails walks X-Forwarded-For past
    # its edges, so a Client-IP header disagreeing with it is routine, not an
    # attack. See config/initializers/rack_request.rb for the companion setting.
    config.action_dispatch.ip_spoofing_check = false
  end
end
