require "test_helper"

class Oauth::MetadataControllerTest < ActionDispatch::IntegrationTest
  test "describes the authorization server" do
    get "/.well-known/oauth-authorization-server"

    json = response.parsed_body
    assert_equal "http://example.com", json["issuer"]
    assert_equal "http://example.com/oauth/token", json["token_endpoint"]
    assert_equal "http://example.com/oauth/register", json["registration_endpoint"]
    assert_equal [ "S256" ], json["code_challenge_methods_supported"]
    assert_equal [ "none" ], json["token_endpoint_auth_methods_supported"]
  end

  test "describes the MCP endpoint from the api host" do
    host! "api.example.com"
    get "/.well-known/oauth-protected-resource/mcp"

    json = response.parsed_body
    assert_equal "http://api.example.com/mcp", json["resource"]
    assert_equal [ "http://example.com" ], json["authorization_servers"]
  end
end
