require "test_helper"

class Api::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "api.example.com"

    @blog = blogs(:joel)
    @blog.update!(features: [ "api" ])
    @user = users(:joel)
    @user.update!(trial_ends_at: 30.days.from_now)

    @post = posts(:one)
    @draft = posts(:joel_draft)
  end

  # -- Authentication --

  test "returns unauthorized without token" do
    get "/posts"
    assert_response :unauthorized
  end

  test "returns unauthorized with invalid token" do
    get "/posts", headers: auth_header("bad-token")
    assert_response :unauthorized
  end

  test "returns forbidden without premium access" do
    @user.subscription.destroy!
    @user.update!(trial_ends_at: nil)
    get "/posts", headers: auth_header
    assert_response :forbidden
  end

  # -- Index --

  test "index returns published and released posts by default" do
    get "/posts", headers: auth_header

    assert_response :success
    posts = JSON.parse(response.body)
    statuses = posts.map { |p| p["status"] }
    assert statuses.all? { |s| s == "published" }, "Expected only published posts"
    assert posts.none? { |p| p["title"] == "Draft post" }
  end

  test "index with status=draft returns only drafts" do
    get "/posts", params: { status: "draft" }, headers: auth_header

    assert_response :success
    posts = JSON.parse(response.body)
    assert posts.all? { |p| p["status"] == "draft" }
    assert posts.any? { |p| p["title"] == "Draft post" }
  end

  test "index with status=published returns published posts" do
    get "/posts", params: { status: "published" }, headers: auth_header

    assert_response :success
    posts = JSON.parse(response.body)
    assert posts.all? { |p| p["status"] == "published" }
  end

  test "index with published_after filters posts" do
    get "/posts", params: { published_after: 1.day.ago.iso8601 }, headers: auth_header

    assert_response :success
    posts = JSON.parse(response.body)
    posts.each do |p|
      assert Time.parse(p["published_at"]) >= 1.day.ago
    end
  end

  test "index with published_before filters posts" do
    get "/posts", params: { published_before: 2.days.ago.iso8601 }, headers: auth_header

    assert_response :success
    posts = JSON.parse(response.body)
    posts.each do |p|
      assert Time.parse(p["published_at"]) <= 2.days.ago
    end
  end

  test "index with date range filters posts" do
    after_time = 5.days.ago.beginning_of_day
    before_time = Time.current.beginning_of_day

    get "/posts", params: {
      published_after: after_time.iso8601,
      published_before: before_time.iso8601
    }, headers: auth_header

    assert_response :success
    posts = JSON.parse(response.body)
    assert posts.any?, "Expected some posts in range"
    posts.each do |p|
      t = Time.parse(p["published_at"])
      assert t >= after_time, "Post published_at #{t} is before #{after_time}"
      assert t <= before_time, "Post published_at #{t} is after #{before_time}"
    end
  end

  test "index includes pagination headers" do
    get "/posts", headers: auth_header

    assert response.headers["X-Total-Count"].present?
    assert response.headers["link"].present?
  end

  test "index returns 400 for invalid published_after timestamp" do
    get "/posts", params: { published_after: "not-a-date" }, headers: auth_header
    assert_response :bad_request
  end

  test "index returns 400 for invalid published_before timestamp" do
    get "/posts", params: { published_before: "garbage" }, headers: auth_header
    assert_response :bad_request
  end

  test "index returns 400 for out-of-range page" do
    get "/posts", params: { page: 999 }, headers: auth_header
    assert_response :bad_request
  end

  # -- Show --

  test "show returns a post" do
    get "/posts/#{@post.token}", headers: auth_header

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @post.title, json["title"]
    assert_equal @post.token, json["token"]
  end

  test "show returns 404 for unknown token" do
    get "/posts/nonexistent", headers: auth_header
    assert_response :not_found
  end

  test "show does not return another blog's post" do
    other_post = posts(:three) # vivian's post
    get "/posts/#{other_post.token}", headers: auth_header
    assert_response :not_found
  end

  # -- Create --

  test "create makes a new published post" do
    assert_difference "Post.count" do
      post "/posts", params: {
        title: "New Post", content: "Hello world", slug: "new-post", status: "published"
      }, headers: auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New Post", json["title"]
    assert_equal "published", json["status"]
  end

  test "create with tags" do
    post "/posts", params: {
      title: "Tagged", content: "Hello", tags: "ruby, rails", status: "published"
    }, headers: auth_header

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal %w[rails ruby], json["tag_list"]
  end

  test "create makes a draft post" do
    assert_difference "Post.count" do
      post "/posts", params: {
        title: "Draft", content: "WIP", status: "draft"
      }, headers: auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "draft", json["status"]
  end

  test "create converts markdown to html when content_format is markdown" do
    post "/posts", params: {
      title: "Markdown Post", content: "Hello **world**", content_format: "markdown", status: "published"
    }, headers: auth_header

    assert_response :created
    json = JSON.parse(response.body)
    assert_includes json["content"], "<strong>world</strong>"
  end

  test "create extracts front matter from markdown" do
    post "/posts", params: {
      content: "---\ntitle: From Front Matter\nslug: fm-slug\ntags:\n  - ruby\n  - rails\nstatus: published\n---\nHello **world**",
      content_format: "markdown"
    }, headers: auth_header

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "From Front Matter", json["title"]
    assert_equal "fm-slug", json["slug"]
    assert_includes json["tag_list"], "ruby"
    assert_includes json["tag_list"], "rails"
    assert_equal "published", json["status"]
    assert_includes json["content"], "<strong>world</strong>"
    assert_not_includes json["content"], "---"
    assert_not_includes json["content"], "front matter"
  end

  test "create prefers explicit params over front matter" do
    post "/posts", params: {
      title: "Explicit Title",
      content: "---\ntitle: FM Title\nstatus: published\n---\nBody",
      content_format: "markdown",
      status: "draft"
    }, headers: auth_header

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Explicit Title", json["title"]
    assert_equal "draft", json["status"]
  end

  test "create handles front matter date field" do
    post "/posts", params: {
      content: "---\ntitle: Dated Post\ndate: '2024-06-15'\nstatus: published\n---\nBody",
      content_format: "markdown"
    }, headers: auth_header

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "2024-06-15", Time.parse(json["published_at"]).strftime("%Y-%m-%d")
  end

  test "create returns 422 with malformed front matter in markdown" do
    post "/posts", params: {
      title: "Broken FM",
      content: "---\ntitle: [invalid\nyaml: :\n---\nBody text",
      content_format: "markdown",
      status: "published"
    }, headers: auth_header

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_match /Invalid front matter/, json["error"]
  end

  test "create leaves html untouched without content_format" do
    post "/posts", params: {
      title: "HTML Post", content: "<p>Hello <strong>world</strong></p>", status: "published"
    }, headers: auth_header

    assert_response :created
    json = JSON.parse(response.body)
    assert_includes json["content"], "<strong>world</strong>"
  end

  test "update converts markdown to html when content_format is markdown" do
    patch "/posts/#{@post.token}", params: {
      content: "Updated **content**", content_format: "markdown"
    }, headers: auth_header

    assert_response :success
    json = JSON.parse(response.body)
    assert_includes json["content"], "<strong>content</strong>"
  end

  test "create returns 400 for invalid status" do
    post "/posts", params: {
      title: "Bad Status", content: "Body", status: "bogus"
    }, headers: auth_header

    assert_response :bad_request
  end

  test "create returns 422 with invalid params" do
    post "/posts", params: { title: "" }, headers: auth_header
    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert json.key?("errors")
  end

  test "create with attachment returns stored html not rendered html" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture("space.jpg").open,
      filename: "space.jpg",
      content_type: "image/jpeg"
    )

    post "/posts", params: {
      title: "With Image",
      content: %(<p>Hello</p><action-text-attachment sgid="#{blob.attachable_sgid}"></action-text-attachment>),
      status: "published"
    }, headers: auth_header

    assert_response :created
    json = JSON.parse(response.body)
    assert_includes json["content"], "action-text-attachment"
    assert_includes json["content"], "sgid="
    assert_not_includes json["content"], "<figure"
    assert_not_includes json["content"], "<img"
  end

  # -- Update --

  test "update changes post attributes" do
    patch "/posts/#{@post.token}", params: { title: "Updated Title" }, headers: auth_header

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Updated Title", json["title"]
    assert_equal "Updated Title", @post.reload.title
  end

  test "update can publish a draft" do
    patch "/posts/#{@draft.token}", params: { status: "published" }, headers: auth_header

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "published", json["status"]
    assert_equal "published", @draft.reload.status
  end

  test "update returns 422 with invalid params" do
    other = posts(:two)
    patch "/posts/#{@post.token}", params: { slug: other.slug }, headers: auth_header
    assert_response :unprocessable_entity
  end

  test "update returns 404 for unknown token" do
    patch "/posts/nonexistent", params: { title: "Nope" }, headers: auth_header
    assert_response :not_found
  end

  test "update cannot modify another blog's post" do
    other_post = posts(:three)
    patch "/posts/#{other_post.token}", params: { title: "Hacked" }, headers: auth_header
    assert_response :not_found
  end

  # -- Destroy --

  test "destroy discards a post" do
    delete "/posts/#{@post.token}", headers: auth_header

    assert_response :no_content
    assert @post.reload.discarded?
  end

  test "destroy returns 404 for unknown token" do
    delete "/posts/nonexistent", headers: auth_header
    assert_response :not_found
  end

  test "destroy cannot discard another blog's post" do
    other_post = posts(:three)
    delete "/posts/#{other_post.token}", headers: auth_header
    assert_response :not_found
  end

  private

    def auth_header(token = "test_api_key_for_fixtures")
      { "Authorization" => "Bearer #{token}" }
    end
end
