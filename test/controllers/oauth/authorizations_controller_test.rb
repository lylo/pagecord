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
    assert_select "p", text: /Please let Claude manage/
    assert_select "select[name=blog_id] option", count: @user.blogs.count
    assert_select "a[href=?]", "#{@redirect_uri}?error=access_denied&state=xyz", text: "Cancel"
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
      post oauth_authorization_path, params: authorize_params(blog_id: blog.id)
    end

    location = URI.parse(response.location)
    query = Rack::Utils.parse_query(location.query)
    assert_equal @redirect_uri, "#{location.scheme}://#{location.host}#{location.path}"
    assert_equal "xyz", query["state"]
    assert_equal blog.mcp_connections.last, McpConnection.find_by_code(query["code"])
  end

  test "reauthorising the same app reuses its connection" do
    login_as @user
    existing = mcp_connections(:joel_claude)

    assert_no_difference -> { McpConnection.count } do
      post oauth_authorization_path, params: authorize_params(client_id: existing.client_id, blog_id: blogs(:joel).id)
    end

    code = Rack::Utils.parse_query(URI.parse(response.location).query)["code"]
    assert_equal existing, McpConnection.find_by_code(code)
  end

  test "cannot connect another user's blog" do
    login_as @user
    post oauth_authorization_path, params: authorize_params(blog_id: blogs(:vivian).id)

    assert_response :not_found
  end

  test "requires premium access to connect" do
    @user.subscription.destroy!
    @user.update!(trial_ends_at: nil)
    login_as @user

    get oauth_authorization_path(authorize_params)
    assert_select "h1", text: "Connecting apps needs a subscription"

    post oauth_authorization_path, params: authorize_params(blog_id: blogs(:joel).id)
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
