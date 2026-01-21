session_options = {
  key: "_pagecord_v2",
  expire_after: 1.year,
  domain: :all
}

# When using a custom domain tool like ngrok in development, the domain
# (e.g., .ngrok-free.app) is often on the public suffix list, which blocks
# wildcard cookies. We disable the explicit domain setting in this case,
# unless it's a domain we own (like dev.pagecord.com).
if Rails.env.development? && ENV["APP_DOMAIN"].present?
  if ENV["APP_DOMAIN"].end_with?(".pagecord.com")
    session_options[:domain] = ".#{ENV["APP_DOMAIN"]}"
  else
    session_options.delete(:domain)
  end
end

Rails.application.config.session_store :cookie_store, **session_options
