require "test_helper"

class Api::MicropubControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "api.example.com"

    @blog = blogs(:joel)
    @user = users(:joel)
    @user.update!(trial_ends_at: 30.days.from_now)

    @post = posts(:one)
  end

  # -- Authentication --

  test "returns unauthorized without token" do
    post "/micropub", params: { h: "entry", name: "Test", content: "Hello" }
    assert_response :unauthorized
  end

  test "returns unauthorized with invalid token" do
    post "/micropub", params: { h: "entry", name: "Test", content: "Hello" }, headers: auth_header("bad-token")
    assert_response :unauthorized
  end

  test "returns forbidden without premium access" do
    @user.subscription.destroy!
    @user.update!(trial_ends_at: nil)
    post "/micropub", params: { h: "entry", name: "Test", content: "Hello" }, headers: auth_header
    assert_response :forbidden
  end

  # -- Create (form-encoded) --

  test "creates a post from form-encoded params" do
    post "/micropub",
      params: { h: "entry", name: "Hello World", content: "Some content" },
      headers: auth_header

    assert_response :created
    assert response.headers["Location"].present?
    assert_includes response.headers["Location"], "hello-world"
  end

  test "creates a draft post" do
    post "/micropub",
      params: { h: "entry", name: "Draft Post", content: "Hello", "post-status": "draft" },
      headers: auth_header

    assert_response :created
    slug = response.headers["Location"].split("/").last
    assert @blog.posts.find_by(slug: slug).draft?
  end

  test "creates a post with tags" do
    post "/micropub",
      params: { h: "entry", name: "Tagged Post", content: "Hello", "category[]": [ "ruby", "rails" ] },
      headers: auth_header

    assert_response :created
    slug = response.headers["Location"].split("/").last
    created_post = @blog.posts.find_by(slug: slug)
    assert_includes created_post.tag_list, "ruby"
    assert_includes created_post.tag_list, "rails"
  end

  test "creates a post with custom slug" do
    post "/micropub",
      params: { h: "entry", name: "Some Post", content: "Hello", "mp-slug": "custom-slug" },
      headers: auth_header

    assert_response :created
    assert_includes response.headers["Location"], "custom-slug"
  end

  # -- Create (JSON) --

  test "creates a post from JSON" do
    post "/micropub",
      params: { h: "entry", name: "JSON Post", content: "Hello from JSON" }.to_json,
      headers: auth_header.merge("Content-Type" => "application/json")

    assert_response :created
    assert response.headers["Location"].present?
  end

  test "creates a post with HTML content via content[html]" do
    post "/micropub",
      params: { h: "entry", name: "HTML Post", content: { html: "<p>Hello <strong>world</strong></p>" } }.to_json,
      headers: auth_header.merge("Content-Type" => "application/json")

    assert_response :created
    slug = response.headers["Location"].split("/").last
    assert_includes @blog.posts.find_by(slug: slug).content.body.to_html, "<strong>world</strong>"
  end

  # -- Create (mf2 JSON - iA Writer format) --

  test "creates a post from mf2 JSON" do
    post "/micropub",
      params: {
        type: [ "h-entry" ],
        properties: {
          name: [ "mf2 Post" ],
          content: [ { html: "<p>Hello from iA Writer</p>" } ],
          "post-status": [ "draft" ]
        }
      }.to_json,
      headers: auth_header.merge("Content-Type" => "application/json")

    assert_response :created
    slug = response.headers["Location"].split("/").last
    created_post = @blog.posts.find_by(slug: slug)
    assert_equal "mf2 Post", created_post.title
    assert created_post.draft?
    assert_includes created_post.content.body.to_html, "Hello from iA Writer"
  end

  # -- Update --

  test "updates a post title via replace" do
    post "/micropub",
      params: { action: "update", url: "http://joel.example.com/#{@post.slug}", replace: { name: [ "New Title" ] } }.to_json,
      headers: auth_header.merge("Content-Type" => "application/json")

    assert_response :ok
    assert_equal "New Title", @post.reload.title
  end

  test "adds tags via add" do
    post "/micropub",
      params: { action: "update", url: "http://joel.example.com/#{@post.slug}", add: { category: [ "newtag" ] } }.to_json,
      headers: auth_header.merge("Content-Type" => "application/json")

    assert_response :ok
    assert_includes @post.reload.tag_list, "newtag"
  end

  test "removes tags via remove" do
    @post.update!(tag_list: [ "photography", "travel" ])

    post "/micropub",
      params: { action: "update", url: "http://joel.example.com/#{@post.slug}", remove: { category: [ "travel" ] } }.to_json,
      headers: auth_header.merge("Content-Type" => "application/json")

    assert_response :ok
    assert_not_includes @post.reload.tag_list, "travel"
    assert_includes @post.reload.tag_list, "photography"
  end

  test "returns 404 when updating nonexistent post" do
    post "/micropub",
      params: { action: "update", url: "http://joel.example.com/no-such-post", replace: { name: [ "X" ] } }.to_json,
      headers: auth_header.merge("Content-Type" => "application/json")

    assert_response :not_found
  end

  # -- Delete --

  test "deletes a post" do
    post "/micropub",
      params: { action: "delete", url: "http://joel.example.com/#{@post.slug}" }.to_json,
      headers: auth_header.merge("Content-Type" => "application/json")

    assert_response :ok
    assert @post.reload.discarded?
  end

  test "returns 404 when deleting nonexistent post" do
    post "/micropub",
      params: { action: "delete", url: "http://joel.example.com/no-such-post" }.to_json,
      headers: auth_header.merge("Content-Type" => "application/json")

    assert_response :not_found
  end

  # -- Query --

  test "q=config returns media endpoint" do
    get "/micropub", params: { q: "config" }, headers: auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "http://api.example.com/micropub/media", json["media-endpoint"]
    assert_equal [], json["syndicate-to"]
  end

  test "q=source returns post properties" do
    get "/micropub", params: { q: "source", url: "http://joel.example.com/#{@post.slug}" }, headers: auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal [ @post.title ], json["properties"]["name"]
    assert_equal [ @post.slug ], json["properties"]["mp-slug"]
  end

  test "q=source returns 404 for unknown post" do
    get "/micropub", params: { q: "source", url: "http://joel.example.com/no-such-post" }, headers: auth_header
    assert_response :not_found
  end

  test "unknown q param returns 400" do
    get "/micropub", params: { q: "unknown" }, headers: auth_header
    assert_response :bad_request
  end

  private

    def auth_header(token = "test_api_key_for_fixtures")
      { "Authorization" => "Bearer #{token}" }
    end
end
