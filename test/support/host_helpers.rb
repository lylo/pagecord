class ActionDispatch::IntegrationTest
  # Rails defaults to www.example.com, but the app serves only the apex and
  # permanently redirects www, so every request would otherwise bounce through
  # a 301. Tests that need another host still call host! themselves.
  setup { host! Rails.application.config.x.domain }

  def host_subdomain!(name)
    host! "#{name}.#{Rails.application.config.x.domain}"
  end
end
