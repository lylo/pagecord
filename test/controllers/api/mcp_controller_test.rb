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
    assert_equal "2025-06-18", result["protocolVersion"]

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

  test "refuses unknown methods and tools" do
    rpc "resources/list"
    assert_equal(-32601, response.parsed_body.dig("error", "code"))

    call_tool "send_newsletter"
    assert_equal(-32602, response.parsed_body.dig("error", "code"))
  end

  test "lists the tools" do
    rpc "tools/list"

    assert_equal %w[ create_post delete_post get_appearance get_custom_code get_image get_page_markup get_post list_posts set_image_alt update_appearance update_custom_code update_post ],
      result["tools"].map { it["name"] }.sort
  end

  test "gives every tool a title and a read-only or destructive hint" do
    rpc "tools/list"

    result["tools"].each do |tool|
      assert tool.dig("annotations", "title").present?, "#{tool["name"]} has no title"
      assert tool["annotations"].key?("readOnlyHint") || tool["annotations"].key?("destructiveHint"), "#{tool["name"]} has no hint"
    end
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

  test "round-trips a post with an image without losing the attachment" do
    blob = ActiveStorage::Blob.create_and_upload!(io: file_fixture("space.jpg").open, filename: "space.jpg", content_type: "image/jpeg")
    post = posts(:one)
    post.update!(content: %(<p>Hello</p><action-text-attachment sgid="#{blob.attachable_sgid}"></action-text-attachment>))

    call_tool "get_post", token: post.token
    assert_equal "http://example.com/rails/active_storage/blobs/redirect/#{blob.signed_id}/space.jpg", tool_output["images"].sole["url"]

    call_tool "update_post", token: post.token, content: tool_output["content"].sub("Hello", "Hello again")

    assert_not result["isError"]
    assert_includes post.reload.content.body.to_html, "Hello again"
    assert_includes post.content.body.to_html, %(sgid="#{blob.attachable_sgid}")
  end

  test "finds a post's images in one query" do
    blobs = 2.times.map { ActiveStorage::Blob.create_and_upload!(io: file_fixture("space.jpg").open, filename: "space.jpg", content_type: "image/jpeg") }
    post = posts(:one)
    post.update!(content: blobs.map { %(<action-text-attachment sgid="#{it.attachable_sgid}" width="1600" alt="Stars"></action-text-attachment>) }.join)
    fragment = post.reload.content.body.fragment

    assert_queries_count(1) { assert_equal blobs, Mcp::Tools::GetPost.send(:image_attachments, fragment).map(&:last) }

    call_tool "get_post", token: post.token
    assert_equal({ "filename" => "space.jpg", "width" => 1600, "height" => nil, "alt" => "Stars" }, tool_output["images"].first.except("url"))
  end

  test "sets an image's alt text without touching the rest of the post" do
    blob = ActiveStorage::Blob.create_and_upload!(io: file_fixture("space.jpg").open, filename: "space.jpg", content_type: "image/jpeg")
    post = posts(:one)
    post.update!(content: %(<p>Hello</p><action-text-attachment sgid="#{blob.attachable_sgid}"></action-text-attachment>))

    call_tool "get_post", token: post.token
    call_tool "set_image_alt", token: post.token, url: tool_output["images"].sole["url"], alt: "A nebula"

    assert_not result["isError"]
    node = post.reload.content.body.fragment.find_all("action-text-attachment").sole
    assert_equal "A nebula", node["alt"]
    assert_equal blob.attachable_sgid, node["sgid"]
    assert_includes post.content.body.to_html, "<p>Hello</p>"
  end

  test "refuses to set alt text on an image that isn't in the post" do
    blob = ActiveStorage::Blob.create_and_upload!(io: file_fixture("space.jpg").open, filename: "space.jpg", content_type: "image/jpeg")
    posts(:one).update!(content: %(<action-text-attachment sgid="#{blob.attachable_sgid}"></action-text-attachment>))

    call_tool "set_image_alt", token: posts(:two).token, url: "https://storage.example.com/#{blob.key}", alt: "A nebula"

    assert_equal "That image isn't in this post", result["content"].first["text"]
  end

  test "shows a post image" do
    blob = ActiveStorage::Blob.create_and_upload!(io: file_fixture("space.jpg").open, filename: "space.jpg", content_type: "image/jpeg")
    posts(:one).update!(content: %(<action-text-attachment sgid="#{blob.attachable_sgid}"></action-text-attachment>))

    call_tool "get_post", token: posts(:one).token
    call_tool "get_image", url: tool_output["images"].sole["url"]

    image = result["content"].sole
    assert_equal "image", image["type"]
    assert_equal "image/webp", image["mimeType"]
    assert_equal "WEBP", Base64.decode64(image["data"])[8, 4]
  end

  test "shows an image from a resized URL in the page markup" do
    blob = ActiveStorage::Blob.create_and_upload!(io: file_fixture("space.jpg").open, filename: "space.jpg", content_type: "image/jpeg")
    posts(:one).update!(content: %(<action-text-attachment sgid="#{blob.attachable_sgid}"></action-text-attachment>))

    call_tool "get_image", url: "https://example.com/cdn-cgi/image/width=1600,format=webp/https://storage.example.com/#{blob.key}"

    assert_equal "image", result["content"].sole["type"]
  end

  test "refuses an image from another blog" do
    blob = ActiveStorage::Blob.create_and_upload!(io: file_fixture("space.jpg").open, filename: "space.jpg", content_type: "image/jpeg")
    posts(:one).update!(blog: blogs(:vivian), content: %(<action-text-attachment sgid="#{blob.attachable_sgid}"></action-text-attachment>))

    call_tool "get_image", url: "http://example.com/rails/active_storage/blobs/redirect/#{blob.signed_id}/space.jpg"

    assert result["isError"]
    assert_equal "No image on this blog has that URL", result["content"].first["text"]
  end

  test "reports missing and malformed arguments as tool errors" do
    call_tool "get_post"
    assert result["isError"]
    assert_match "token", result["content"].first["text"]

    rpc "tools/call", { name: "get_post", arguments: "nope" }
    assert_equal(-32602, response.parsed_body.dig("error", "code"))
  end

  test "treats null fields as not given" do
    call_tool "update_appearance", theme: nil, font: "serif"

    assert_not result["isError"]
    assert_equal "serif", @blog.reload.font
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
    assert_equal "mint", tool_output["theme"]
    assert_equal "http://joel.example.com/", tool_output["url"]
  end

  test "reports invalid appearance as a tool error" do
    call_tool "update_appearance", theme: "custom", custom_theme_bg_light: "blue"

    assert result["isError"]
    assert_match "valid hex color", result["content"].first["text"]
  end

  test "changes custom code" do
    call_tool "update_custom_code", custom_css: "body { color: blue }", custom_code_enabled: true

    assert_not result["isError"]
    assert_equal "body { color: blue }", @blog.reload.custom_css
    assert @blog.custom_code_enabled?
    assert_equal %w[ custom_css ], tool_output["changed"]
    assert_equal({ "bytes" => 20, "limit" => Css::Sanitizer::MAX_CSS_SIZE }, tool_output["sizes"]["custom_css"])
  end

  test "checks custom code without saving it" do
    call_tool "update_custom_code", custom_css: "body { color: blue }", dry_run: true

    assert tool_output["valid"]
    assert_not tool_output["saved"]
    assert_equal %w[ custom_css ], tool_output["changed"]
    assert_nil @blog.reload.custom_css
  end

  test "says why custom code is rejected" do
    call_tool "update_custom_code", custom_css: "a { color: red; }\nb { colour: blue; }", dry_run: true

    assert result["isError"]
    assert_equal "Line 2: the colour property isn't supported.", result["content"].first["text"]
  end

  test "shows the home page markup without scripts" do
    call_tool "get_page_markup"

    assert_equal 200, tool_output["status"]
    assert_includes tool_output["html"], %(<article class="post)
    assert_not_includes tool_output["html"], "<script"
    assert tool_output["stylesheets"].any? { it.include?("/blogs") }
  end

  test "shortens only long runs of similar elements in the markup" do
    body = Nokogiri::HTML5("<body><nav>#{"<a>Link</a>" * 6}</nav><main>#{"<article>Post</article>" * 12}</main></body>").at("body")
    html = Mcp::Tools::GetPageMarkup.send(:outline, body)

    assert_equal 6, html.scan("<a>").size
    assert_equal 3, html.scan("<article>").size
    assert_includes html, "<!-- 9 more article -->"
  end

  test "shows a post's markup by slug" do
    call_tool "get_page_markup", page_type: "post", slug: posts(:one).slug

    assert_equal "http://joel.example.com/#{posts(:one).slug}", tool_output["url"]
    assert_includes tool_output["html"], %(data-slug="#{posts(:one).slug}")
  end

  test "shows the markup of a password protected blog" do
    @blog.update!(password: "letmein")
    call_tool "get_page_markup"

    assert_equal 200, tool_output["status"]
    assert_includes tool_output["html"], %(<article class="post)
  end

  test "keeps head and body HTML for subscribers" do
    @user.subscription.destroy!
    @user.update!(trial_ends_at: 30.days.from_now)

    call_tool "update_custom_code", custom_head_html: %(<meta name="x">)

    assert result["isError"]
    assert_equal "custom_head_html requires a subscription", result["content"].first["text"]
    assert_nil @blog.reload.custom_head_html
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
