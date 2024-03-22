source "https://rubygems.org"

ruby "3.3.0"

gem "rails", github: "rails/rails", branch: "main"

gem "importmap-rails"
gem "jbuilder"
gem "sprockets-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "turbo-rails"

gem "puma", ">= 5.0"

# database
gem "dalli"
gem "pg"
gem "redis", ">= 4.0.1"
gem "sidekiq"

# monitoring and alerting
gem "sentry-ruby"
gem "sentry-rails"


gem "inline_svg", "~> 1.9"
gem "pagy", "~> 7.0"
gem "postmark-rails"
gem "premailer-rails", "~> 1.12"
gem "nanoid", "~> 2.0"


# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  gem "sqlite3", "~> 1.4"

  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  gem "letter_opener", "~> 1.9"
  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "rails-controller-testing"
  gem "selenium-webdriver"
end
