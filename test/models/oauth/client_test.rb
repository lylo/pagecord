require "test_helper"

class Oauth::ClientTest < ActiveSupport::TestCase
  test "finds a registered client from its id" do
    client = Oauth::Client.find(Oauth::Client.register(name: "Claude", redirect_uris: [ "https://claude.ai/api/mcp/auth_callback" ]))

    assert_equal "Claude", client.name
    assert client.redirect_uri_allowed?("https://claude.ai/api/mcp/auth_callback")
    assert_not client.redirect_uri_allowed?("https://example.org/callback")
  end

  test "a tampered id finds nothing" do
    assert_nil Oauth::Client.find(Oauth::Client.register(name: "Claude", redirect_uris: []) + "x")
    assert_nil Oauth::Client.find("garbage")
  end

  test "loopback redirects match on any port" do
    client = Oauth::Client.find(Oauth::Client.register(name: "Claude Code", redirect_uris: [ "http://localhost/callback" ]))

    assert client.redirect_uri_allowed?("http://localhost:3118/callback")
    assert_not client.redirect_uri_allowed?("http://localhost:3118/other")
  end

  test "accepts https and loopback redirect uris only" do
    assert Oauth::Client.redirect_uri_acceptable?("https://chatgpt.com/connector_platform_oauth_redirect")
    assert Oauth::Client.redirect_uri_acceptable?("http://127.0.0.1:5555/callback")
    assert_not Oauth::Client.redirect_uri_acceptable?("http://example.org/callback")
    assert_not Oauth::Client.redirect_uri_acceptable?("javascript:alert(1)")
  end
end
