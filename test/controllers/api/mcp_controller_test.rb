require "test_helper"

class Api::McpControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "api.example.com"

    @blog = blogs(:joel)
    @user = users(:joel)
  end

  test "asks for authorization with a pointer to the metadata" do
    rpc "tools/list", token: nil

    assert_response :unauthorized
    assert_includes response.headers["WWW-Authenticate"], %(resource_metadata="http://api.example.com/.well-known/oauth-protected-resource/mcp")
  end

  test "accepts an MCP token or an API key" do
    rpc "initialize", { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "test", version: "1" } }
    assert_equal "pagecord", result["serverInfo"]["name"]

    rpc "tools/list", token: "test_api_key_for_fixtures"
    assert_response :success
  end

  test "stops working once disconnected" do
    mcp_connections(:joel_claude).destroy

    rpc "tools/list"
    assert_response :unauthorized
  end

  test "requires premium access" do
    @user.subscription.destroy!
    @user.update!(trial_ends_at: nil)

    rpc "tools/list"
    assert_response :forbidden
  end

  test "acknowledges notifications" do
    post "/mcp", params: { jsonrpc: "2.0", method: "notifications/initialized" }, headers: auth_header, as: :json

    assert_response :accepted
  end

  test "lists the tools" do
    rpc "tools/list"

    assert_equal %w[ create_post delete_post get_appearance get_post list_posts update_appearance update_post ],
      result["tools"].map { it["name"] }.sort
  end

  test "lists drafts" do
    call_tool "list_posts", status: "draft"

    assert_includes tool_output["posts"].map { it["token"] }, posts(:joel_draft).token
  end

  test "reads a post as Markdown" do
    call_tool "get_post", token: posts(:one).token

    assert_equal posts(:one).title, tool_output["title"]
    assert tool_output["content"].present?
  end

  test "creates a draft from Markdown" do
    assert_difference -> { @blog.posts.count } do
      call_tool "create_post", title: "From a chat", content: "Some **bold** words"
    end

    post = @blog.posts.last
    assert post.draft?
    assert post.api?
    assert_includes post.content.to_s, "<strong>bold</strong>"
  end

  test "publishes a draft" do
    draft = posts(:joel_draft)
    call_tool "update_post", token: draft.token, status: "published"

    assert draft.reload.published?
    assert tool_output["url"].present?
  end

  test "moves a post to the trash" do
    call_tool "delete_post", token: posts(:one).token

    assert posts(:one).reload.discarded?
  end

  test "reports a missing post as a tool error" do
    call_tool "get_post", token: "nope"

    assert result["isError"]
  end

  test "changes the theme and ignores fields it does not declare" do
    call_tool "update_appearance", theme: "mint", subdomain: "hijacked"

    @blog.reload
    assert_equal "mint", @blog.theme
    assert_equal "joel", @blog.subdomain
  end

  test "reports invalid appearance as a tool error" do
    call_tool "update_appearance", theme: "custom", custom_theme_bg_light: "blue"

    assert result["isError"]
    assert_match "valid hex color", result["content"].first["text"]
  end

  test "does not open a stream" do
    get "/mcp", headers: auth_header

    assert_response :method_not_allowed
  end

  private

    def rpc(method, params = nil, token: "test_mcp_token")
      post "/mcp", params: { jsonrpc: "2.0", id: 1, method: method, params: params }.compact, headers: auth_header(token), as: :json
    end

    def call_tool(name, **arguments)
      rpc "tools/call", { name: name, arguments: arguments }
    end

    def result
      response.parsed_body["result"]
    end

    def tool_output
      JSON.parse(result["content"].first["text"])
    end

    def auth_header(token = "test_mcp_token")
      token ? { "Authorization" => "Bearer #{token}" } : {}
    end
end
