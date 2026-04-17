session_options = {
  key: "_pagecord_v2",
  expire_after: 1.year,
  domain: :all
}

if Rails.env.development? && ENV["APP_DOMAIN"].present?
  session_options[:domain] = ".#{ENV['APP_DOMAIN']}"
end

Rails.application.config.session_store :cookie_store, **session_options
