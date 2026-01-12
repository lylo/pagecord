require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome

  setup do
    Capybara.always_include_port = true
  end

  def use_subdomain(subdomain, path = "/")
    port = Capybara.current_session.server.port
    Capybara.app_host = "http://#{subdomain}.localhost:#{port}"
  end

  teardown do
    Capybara.app_host = nil
  end
end
