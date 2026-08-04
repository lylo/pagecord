require "test_helper"

class WwwRedirectTest < ActionDispatch::IntegrationTest
  test "redirects www to the apex domain" do
    host! "www.example.com"
    get "/"

    assert_redirected_to "http://example.com/"
    assert_equal 301, response.status
  end

  test "preserves the path and query string" do
    host! "www.example.com"
    get "/login?return_to=%2Fapp"

    assert_redirected_to "http://example.com/login?return_to=%2Fapp"
  end

  test "leaves the apex domain alone" do
    host! "example.com"
    get "/login"

    assert_response :success
  end

  test "redirects non-GET requests too" do
    host! "www.example.com"
    post "/sessions"

    assert_redirected_to "http://example.com/sessions"
  end

  # Customer blogs are reachable on www too, and blogs/base_controller already
  # canonicalises them to the customer's own apex. The constraint above matches
  # the app domain exactly, so those are not swept into it.
  test "sends customer www domains to their own apex, not ours" do
    blog = blogs(:annie)
    host! "www.#{blog.custom_domain}"
    get "/"

    assert_redirected_to "http://#{blog.custom_domain}/"
  end

  # www is no longer a default domain, so nothing reaches an app controller on
  # it even if the redirect above is ever bypassed.
  test "www is not treated as the app host" do
    request = ActionDispatch::Request.new("HTTP_HOST" => "www.example.com")

    assert_not DomainConstraints.default_domain?(request)
  end
end
