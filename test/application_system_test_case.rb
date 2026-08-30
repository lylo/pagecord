require "test_helper"

# Chrome reports detached nodes as UnknownError rather than
# StaleElementReferenceError, so Capybara won't retry them
# https://github.com/teamcapybara/capybara/issues/2800
Capybara::Selenium::Driver.class_eval do
  def invalid_element_errors
    super + [ Selenium::WebDriver::Error::UnknownError ]
  end
end

# In Docker, use the Chromium and driver installed by the Dockerfile's dev stage
# rather than letting Selenium Manager download a browser at test time.
Selenium::WebDriver::Chrome::Service.driver_path = "/usr/bin/chromedriver" if ENV["RUNNING_IN_DOCKER"]

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome do |options|
    if ENV["RUNNING_IN_DOCKER"]
      options.binary = "/usr/bin/chromium"
      # Chromium's sandbox needs privileges the container doesn't have
      options.add_argument("--no-sandbox")
    end
  end

  setup do
    Capybara.always_include_port = true
    Capybara.app_host = "http://localhost:#{Capybara.current_session.server.port}"
  end

  # Browsers resolve any .localhost name to loopback without a DNS lookup. The
  # extra label is there because request.subdomain drops tld_length + 1 of them,
  # and a two-label host would leave nothing behind.
  def use_subdomain(subdomain, path = "/")
    port = Capybara.current_session.server.port
    Capybara.app_host = "http://#{subdomain}.pagecord.localhost:#{port}"
  end

  teardown do
    Capybara.app_host = nil
  end
end
