source "https://rubygems.org"

ruby "3.3.1"

gem "rails", github: "rails/rails", branch: "main"

gem "actionpack-page_caching"
gem "image_processing", "~> 1.2"
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

gem "aws-sdk-s3"
gem "discard", "~> 1.2"
gem "fastimage"
gem "htmlentities"
gem "httparty"
gem "inline_svg"
gem "pagy"
gem "postmark-rails"
gem "premailer-rails", "~> 1.12"
gem "nanoid", "~> 2.0"
gem "rails_autolink"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

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
  gem "mocha"
  gem "rails-controller-testing"
  gem "selenium-webdriver"
end
