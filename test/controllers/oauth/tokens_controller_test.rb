require "test_helper"

class Oauth::TokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @connection = mcp_connections(:joel_pending)
  end

  test "exchanges a code for a token once" do
    post oauth_token_path, params: exchange_params

    assert_response :success
    assert_equal @connection, McpConnection.find_by_token(response.parsed_body["access_token"])

    post oauth_token_path, params: exchange_params
    assert_equal "invalid_grant", response.parsed_body["error"]
  end

  test "refuses a wrong code verifier" do
    post oauth_token_path, params: exchange_params(code_verifier: "wrong")

    assert_response :bad_request
    assert_equal "invalid_grant", response.parsed_body["error"]
  end

  test "refuses a different redirect uri" do
    post oauth_token_path, params: exchange_params(redirect_uri: "https://example.org/callback")

    assert_equal "invalid_grant", response.parsed_body["error"]
  end

  test "refuses an expired code" do
    travel McpConnection::CODE_LIFETIME do
      post oauth_token_path, params: exchange_params
    end

    assert_equal "invalid_grant", response.parsed_body["error"]
  end

  test "refuses other grant types" do
    post oauth_token_path, params: exchange_params(grant_type: "client_credentials")

    assert_equal "unsupported_grant_type", response.parsed_body["error"]
  end

  private

    def exchange_params(**overrides)
      {
        grant_type: "authorization_code",
        code: "test_mcp_code",
        client_id: @connection.client_id,
        redirect_uri: @connection.redirect_uri,
        code_verifier: "test_verifier"
      }.merge(overrides)
    end
end
