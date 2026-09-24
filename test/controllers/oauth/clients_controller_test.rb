require "test_helper"

class Oauth::ClientsControllerTest < ActionDispatch::IntegrationTest
  test "registers a client" do
    post oauth_registration_path, params: { client_name: "Claude", redirect_uris: [ "https://claude.ai/api/mcp/auth_callback" ] }, as: :json

    assert_response :created
    client = Oauth::Client.find(response.parsed_body["client_id"])
    assert_equal "Claude", client.name
    assert_equal "none", response.parsed_body["token_endpoint_auth_method"]
  end

  test "rejects a plain http redirect" do
    post oauth_registration_path, params: { client_name: "Sneaky", redirect_uris: [ "http://example.org/callback" ] }, as: :json

    assert_response :bad_request
    assert_equal "invalid_redirect_uri", response.parsed_body["error"]
  end
end
