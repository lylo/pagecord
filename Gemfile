source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", github: "rails/rails", branch: "main"

gem "actionpack-page_caching"
gem "image_processing", "~> 1.2"
gem "importmap-rails"
gem "jbuilder"
gem "ruby-vips"
gem "sprockets-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "turbo-rails"

gem "puma", ">= 5.0"

# database / caching
gem "dalli"
gem "kredis", "~> 1.7"
gem "pg"
gem "redis", ">= 4.0.1"
gem "sidekiq"

# monitoring and alerting
gem "appsignal"
gem "pghero"
gem "pg_query", ">= 2"
gem "rollups"  # Analytics data aggregation
gem "sentry-ruby"
gem "sentry-rails"

# email sending and receiving
gem "mailpace-rails"
gem "postmark-rails"
gem "premailer-rails", "~> 1.12"

# everything else
gem "aws-sdk-s3"
gem "discard", "~> 1.2"
gem "redcarpet"
gem "pg_search"
gem "fastimage"
gem "feature_toggles"
gem "htmlentities"
gem "httparty"
gem "inline_svg"
gem "local_time"
gem "ostruct"
gem "pagy"
gem "nanoid", "~> 2.0"
gem "rack-attack"
gem "rails_autolink"
gem "rubyzip", "~> 3"
gem "whenever"
gem "tzinfo-data"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :production do
  gem "cloudflare-rails"
end

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  gem "letter_opener"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

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
