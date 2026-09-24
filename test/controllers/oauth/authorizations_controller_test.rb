require "test_helper"

class Oauth::AuthorizationsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @redirect_uri = "https://claude.ai/api/mcp/auth_callback"
    @client_id = Oauth::Client.register(name: "Claude", redirect_uris: [ @redirect_uri ])
  end

  test "returns to the consent page after logging in" do
    get oauth_authorization_path(authorize_params)
    assert_redirected_to login_path

    login_as @user
    assert_redirected_to oauth_authorization_path(authorize_params)
  end

  test "asks which blog to connect" do
    login_as @user
    get oauth_authorization_path(authorize_params)

    assert_response :success
    assert_select "h1", text: "Connect Claude to Pagecord"
    assert_select "input[type=radio][name=blog_id]", count: @user.blogs.count
  end

  test "refuses a redirect the client did not register" do
    login_as @user
    get oauth_authorization_path(authorize_params(redirect_uri: "https://example.org/callback"))

    assert_response :unprocessable_entity
  end

  test "refuses a request without PKCE" do
    login_as @user
    get oauth_authorization_path(authorize_params(code_challenge: nil))

    assert_response :unprocessable_entity
  end

  test "allowing connects the chosen blog and returns a code" do
    login_as @user
    blog = blogs(:joel_notes)

    assert_difference -> { blog.mcp_connections.count } do
      post oauth_authorization_path, params: authorize_params(blog_id: blog.id, decision: "allow")
    end

    location = URI.parse(response.location)
    query = Rack::Utils.parse_query(location.query)
    assert_equal @redirect_uri, "#{location.scheme}://#{location.host}#{location.path}"
    assert_equal "xyz", query["state"]
    assert_equal blog.mcp_connections.last, McpConnection.find_by_code(query["code"])
  end

  test "cancelling returns access_denied" do
    login_as @user

    assert_no_difference -> { McpConnection.count } do
      post oauth_authorization_path, params: authorize_params(blog_id: blogs(:joel).id, decision: "deny")
    end

    assert_redirected_to "#{@redirect_uri}?error=access_denied&state=xyz"
  end

  test "cannot connect another user's blog" do
    login_as @user
    post oauth_authorization_path, params: authorize_params(blog_id: blogs(:vivian).id, decision: "allow")

    assert_response :not_found
  end

  test "requires premium access to connect" do
    @user.subscription.destroy!
    @user.update!(trial_ends_at: nil)
    login_as @user

    post oauth_authorization_path, params: authorize_params(blog_id: blogs(:joel).id, decision: "allow")

    assert_response :forbidden
  end

  private

    def authorize_params(**overrides)
      {
        response_type: "code",
        client_id: @client_id,
        redirect_uri: @redirect_uri,
        state: "xyz",
        code_challenge: "challenge",
        code_challenge_method: "S256"
      }.merge(overrides).compact
    end
end
