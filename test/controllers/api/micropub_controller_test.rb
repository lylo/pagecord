require "test_helper"

class Api::MicropubControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "api.example.com"

    @blog = blogs(:joel)
    @user = users(:joel)
    @user.update!(trial_ends_at: 30.days.from_now)

    @post = posts(:one)
  end

  test "returns unauthorized without token" do
    post "/micropub", params: { h: "entry", name: "Test", content: "Hello" }

    assert_response :unauthorized
    assert_equal "unauthorized", JSON.parse(response.body)["error"]
  end

  test "returns unauthorized with invalid token" do
    post "/micropub", params: { h: "entry", name: "Test", content: "Hello" }, headers: auth_header("bad-token")

    assert_response :unauthorized
    assert_equal "insufficient_scope", JSON.parse(response.body)["error"]
  end

  test "accepts access token form parameter" do
    post "/micropub", params: {
      h: "entry", name: "Form Token", content: "Hello", access_token: "test_api_key_for_fixtures"
    }

    assert_response :created
  end

  test "returns forbidden without premium access" do
    @user.subscription.destroy!
    @user.update!(trial_ends_at: nil)

    post "/micropub", params: { h: "entry", name: "Test", content: "Hello" }, headers: auth_header

    assert_response :forbidden
  end

  test "creates a post from form encoded params" do
    assert_difference "Post.count" do
      post "/micropub",
        params: { h: "entry", name: "Hello World", content: "Some **content**" },
        headers: auth_header
    end

    assert_response :created
    assert_includes response.headers["Location"], "hello-world"

    created_post = @blog.posts.find_by(slug: "hello-world")
    assert_equal "Hello World", created_post.title
    assert_includes created_post.content.body.to_html, "<strong>content</strong>"
  end

  test "returns edit location for draft posts" do
    post "/micropub",
      params: {
        type: [ "h-entry" ],
        properties: {
          name: [ "Draft Post" ],
          content: [ "Hello" ],
          "post-status": [ "draft" ]
        }
      }.to_json,
      headers: auth_header.merge("Content-Type" => "application/json")

    assert_response :created
    created_post = @blog.posts.find_by!(token: response.headers["Location"].split("/")[-2])
    assert_equal edit_app_post_url(created_post, host: "example.com"), response.headers["Location"]
  end

  test "creates a draft post with tags and custom slug" do
    post "/micropub",
      params: {
        h: "entry",
        name: "Draft Post",
        content: "Hello",
        "category[]": [ "ruby", "rails" ],
        "mp-slug": "custom-slug",
        "post-status": "draft"
      },
      headers: auth_header

    assert_response :created
    created_post = @blog.posts.find_by(slug: "custom-slug")
    assert created_post.draft?
    assert_equal %w[rails ruby], created_post.tag_list
  end

  test "creates a post from mf2 json" do
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
    created_post = @blog.posts.find_by(slug: "mf2-post")
    assert_equal "mf2 Post", created_post.title
    assert created_post.draft?
    assert_includes created_post.content.body.to_html, "Hello from iA Writer"
  end

  test "creates a post from mf2 content value" do
    post "/micropub",
      params: {
        type: [ "h-entry" ],
        properties: {
          name: [ "mf2 Value Post" ],
          content: [ { value: "Hello **from value**" } ]
        }
      }.to_json,
      headers: auth_header.merge("Content-Type" => "application/json")

    assert_response :created
    created_post = @blog.posts.find_by(slug: "mf2-value-post")
    assert_includes created_post.content.body.to_html, "<strong>from value</strong>"
  end

  test "rejects invalid post status" do
    post "/micropub",
      params: { h: "entry", content: "Hello", "post-status": "queued" },
      headers: auth_header

    assert_response :bad_request
    assert_equal "invalid_request", JSON.parse(response.body)["error"]
  end

  test "media endpoint uploads file and returns location" do
    file = fixture_file_upload("space.jpg", "image/jpeg")

    assert_difference -> { ActiveStorage::Blob.count } do
      post "/micropub/media", params: { file: file }, headers: auth_header
    end

    assert_response :created
    assert_includes response.headers["Location"], "/rails/active_storage/blobs/"
    assert_empty response.body
  end

  test "media endpoint accepts access token form parameter" do
    file = fixture_file_upload("space.jpg", "image/jpeg")

    assert_difference -> { ActiveStorage::Blob.count } do
      post "/micropub/media", params: { file: file, access_token: "test_api_key_for_fixtures" }
    end

    assert_response :created
    assert_includes response.headers["Location"], "/rails/active_storage/blobs/"
  end

  test "creates post with uploaded media url as action text attachment" do
    file = fixture_file_upload("space.jpg", "image/jpeg")
    post "/micropub/media", params: { file: file }, headers: auth_header
    media_url = response.headers["Location"]

    post "/micropub",
      params: {
        type: [ "h-entry" ],
        properties: {
          name: [ "Photo Post" ],
          content: [ "A photo" ],
          photo: [ { value: media_url, alt: "Stars" } ]
        }
      }.to_json,
      headers: auth_header.merge("Content-Type" => "application/json")

    assert_response :created
    created_post = @blog.posts.find_by(slug: "photo-post")
    stored_html = created_post.content.body.to_html
    assert_includes stored_html, "action-text-attachment"
    assert_includes stored_html, 'caption="Stars"'
  end

  test "updates a post with replace and returns created when url changes" do
    post "/micropub",
      params: {
        action: "update",
        url: "http://joel.example.com/#{@post.slug}",
        replace: {
          name: [ "New Title" ],
          "mp-slug": [ "new-slug" ]
        }
      }.to_json,
      headers: auth_header.merge("Content-Type" => "application/json")

    assert_response :created
    assert_includes response.headers["Location"], "new-slug"
    assert_equal "New Title", @post.reload.title
    assert_equal "new-slug", @post.slug
  end

  test "adds and deletes tags via update" do
    @post.update!(tag_list: [ "photography", "travel" ])

    post "/micropub",
      params: {
        action: "update",
        url: "http://joel.example.com/#{@post.slug}",
        add: { category: [ "newtag" ] },
        delete: { category: [ "travel" ] }
      }.to_json,
      headers: auth_header.merge("Content-Type" => "application/json")

    assert_response :ok
    assert_includes @post.reload.tag_list, "newtag"
    assert_includes @post.tag_list, "photography"
    assert_not_includes @post.tag_list, "travel"
  end

  test "deletes a post" do
    post "/micropub",
      params: { action: "delete", url: "http://joel.example.com/#{@post.slug}" }.to_json,
      headers: auth_header.merge("Content-Type" => "application/json")

    assert_response :ok
    assert @post.reload.discarded?
  end

  test "update rejects urls from other hosts" do
    assert_no_changes -> { @post.reload.title } do
      post "/micropub",
        params: {
          action: "update",
          url: "http://elsewhere.example.com/#{@post.slug}",
          replace: { name: [ "Wrong Host" ] }
        }.to_json,
        headers: auth_header.merge("Content-Type" => "application/json")
    end

    assert_response :not_found
  end

  test "config query returns media endpoint and empty syndication targets" do
    get "/micropub", params: { q: "config" }, headers: auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "http://api.example.com/micropub/media", json["media-endpoint"]
    assert_equal [], json["syndicate-to"]
    assert_equal %w[published draft], json["post-status"]
  end

  test "config query advertises micropub endpoint" do
    get "/micropub", params: { q: "config" }

    assert_response :ok
    assert_equal '<http://api.example.com/micropub>; rel="micropub"', response.headers["Link"]
  end

  test "blank query returns public config for client setup" do
    get "/micropub"

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal "http://api.example.com/micropub/media", json["media-endpoint"]
    assert_equal [], json["syndicate-to"]
  end

  test "config query does not require authentication" do
    get "/micropub", params: { q: "config" }

    assert_response :ok
  end

  test "syndicate to query returns empty targets" do
    get "/micropub", params: { q: "syndicate-to" }, headers: auth_header

    assert_response :ok
    assert_equal({ "syndicate-to" => [] }, JSON.parse(response.body))
  end

  test "source query requires authentication" do
    get "/micropub", params: { q: "source", url: "http://joel.example.com/#{@post.slug}" }

    assert_response :unauthorized
  end

  test "source query returns post properties" do
    get "/micropub", params: { q: "source", url: "http://joel.example.com/#{@post.slug}" }, headers: auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal [ "h-entry" ], json["type"]
    assert_equal [ @post.title ], json["properties"]["name"]
    assert_equal [ @post.slug ], json["properties"]["mp-slug"]
  end

  test "source query returns simple content as text" do
    post "/micropub",
      params: {
        h: "entry",
        content: "Test of querying the endpoint for the source content",
        "category[]": [ "micropub", "test" ]
      },
      headers: auth_header

    created_post = @blog.posts.find_by!(slug: response.headers["Location"].split("/").last)

    get "/micropub", params: { q: "source", url: "http://joel.example.com/#{created_post.slug}" }, headers: auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json["properties"].key?("name")
    assert_equal [ "Test of querying the endpoint for the source content" ], json["properties"]["content"]
    assert_equal %w[micropub test], json["properties"]["category"]
  end

  test "source query filters requested properties" do
    get "/micropub",
      params: {
        q: "source",
        url: "http://joel.example.com/#{@post.slug}",
        "properties[]": [ "name", "content", "mp-slug", "post-status" ]
      },
      headers: auth_header

    assert_response :ok
    json = JSON.parse(response.body)
    assert_not json.key?("type")
    assert_equal %w[content mp-slug name post-status], json["properties"].keys.sort
    assert_equal [ @post.slug ], json["properties"]["mp-slug"]
    assert_equal [ @post.status ], json["properties"]["post-status"]
  end

  test "source query accepts posts path urls" do
    get "/micropub", params: { q: "source", url: "http://joel.example.com/posts/#{@post.slug}" }, headers: auth_header

    assert_response :ok
  end

  test "source query accepts custom domain urls" do
    @blog.update!(custom_domain: "joel.test")

    get "/micropub", params: { q: "source", url: "http://joel.test/#{@post.slug}" }, headers: auth_header

    assert_response :ok
  end

  test "source query rejects urls from other hosts" do
    get "/micropub", params: { q: "source", url: "http://elsewhere.example.com/#{@post.slug}" }, headers: auth_header

    assert_response :not_found
  end

  test "unknown query returns bad request" do
    get "/micropub", params: { q: "unknown" }, headers: auth_header

    assert_response :bad_request
    assert_equal "invalid_request", JSON.parse(response.body)["error"]
  end

  test "unknown action returns bad request" do
    post "/micropub",
      params: { action: "undelete", url: "http://joel.example.com/#{@post.slug}" }.to_json,
      headers: auth_header.merge("Content-Type" => "application/json")

    assert_response :bad_request
    assert_equal "invalid_request", JSON.parse(response.body)["error"]
  end

  private

    def auth_header(token = "test_api_key_for_fixtures")
      { "Authorization" => "Bearer #{token}" }
    end
end
