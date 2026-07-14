class ActionDispatch::IntegrationTest
  def host_subdomain!(name)
    host! "#{name}.#{Rails.application.config.x.domain}"
  end
end
