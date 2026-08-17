require "test_helper"

class LegacyBlogPathRedirectTest < ActionDispatch::IntegrationTest
  test "redirects a legacy blog path to the subdomain" do
    host! "example.com"
    get "/joel/some-post"

    assert_redirected_to "http://joel.example.com/some-post"
  end

  test "redirects the bare legacy blog root" do
    host! "example.com"
    get "/joel"

    assert_redirected_to "http://joel.example.com/"
  end

  # Scanners and link-rotted URLs send paths with characters that are illegal in
  # a URI. Interpolating those straight into the Location raised
  # URI::InvalidURIError rather than redirecting.
  test "escapes path characters that are illegal in a URI" do
    host! "example.com"
    get "/joel/foo%5Bbar%5D"

    assert_redirected_to "http://joel.example.com/foo%5Bbar%5D"
  end
end
