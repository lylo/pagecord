require "test_helper"

class Api::PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "api.example.com"

    @blog = blogs(:joel)
    @blog.update!(features: [ "api" ])
    @user = users(:joel)
    @user.update!(trial_ends_at: 30.days.from_now)

    @page = posts(:about)
    @draft_page = posts(:draft_page)
  end

  # -- Index --

  test "index returns published and released pages by default" do
    get "/pages", headers: auth_header

    assert_response :success
    pages = JSON.parse(response.body)
    assert pages.all? { |p| p["status"] == "published" }
    assert pages.all? { |p| p["is_page"] == true }
    assert pages.none? { |p| p["title"] == "Draft Page" }
  end

  test "index with status=draft returns only drafts" do
    get "/pages", params: { status: "draft" }, headers: auth_header

    assert_response :success
    pages = JSON.parse(response.body)
    assert pages.all? { |p| p["status"] == "draft" }
    assert pages.any? { |p| p["title"] == "Draft Page" }
  end

  test "index includes pagination headers" do
    get "/pages", headers: auth_header

    assert response.headers["X-Total-Count"].present?
    assert response.headers["link"].present?
  end

  test "index does not include posts" do
    get "/pages", headers: auth_header

    pages = JSON.parse(response.body)
    titles = pages.map { |p| p["title"] }
    assert_not_includes titles, "The Art of Street Photography"
  end

  test "index returns 400 for invalid published_after timestamp" do
    get "/pages", params: { published_after: "not-a-date" }, headers: auth_header
    assert_response :bad_request
  end

  test "index returns 400 for out-of-range page" do
    get "/pages", params: { page: 999 }, headers: auth_header
    assert_response :bad_request
  end

  # -- Show --

  test "show returns a page" do
    get "/pages/#{@page.token}", headers: auth_header

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @page.title, json["title"]
    assert_equal @page.token, json["token"]
    assert_equal true, json["is_page"]
    assert_not json.key?("show_in_navigation")
  end

  test "show includes is_home_page field" do
    @blog.update!(home_page_id: @page.id)

    get "/pages/#{@page.token}", headers: auth_header

    json = JSON.parse(response.body)
    assert_equal true, json["is_home_page"]
  end

  test "show returns 404 for unknown token" do
    get "/pages/nonexistent", headers: auth_header
    assert_response :not_found
  end

  test "show does not return another blog's page" do
    other_page = posts(:non_nav_page) # elliot's page
    get "/pages/#{other_page.token}", headers: auth_header
    assert_response :not_found
  end

  # -- Create --

  test "create makes a new page" do
    assert_difference "Post.count" do
      post "/pages", params: {
        title: "New Page", content: "Page content", slug: "new-page", status: "published"
      }, headers: auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New Page", json["title"]
    assert_equal true, json["is_page"]
    assert_not json.key?("show_in_navigation")
    assert Post.find_by(token: json["token"]).is_page?
  end

  test "create converts markdown to html when content_format is markdown" do
    post "/pages", params: {
      title: "MD Page", content: "Hello **world**", content_format: "markdown", status: "published"
    }, headers: auth_header

    assert_response :created
    json = JSON.parse(response.body)
    assert_includes json["content"], "<strong>world</strong>"
  end

  test "create extracts front matter from markdown" do
    post "/pages", params: {
      content: "---\ntitle: From Front Matter\nslug: fm-page\nstatus: published\n---\nPage **body**",
      content_format: "markdown"
    }, headers: auth_header

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "From Front Matter", json["title"]
    assert_equal "fm-page", json["slug"]
    assert_includes json["content"], "<strong>body</strong>"
  end

  test "create returns 400 for invalid status" do
    post "/pages", params: {
      title: "Bad Status", content: "Body", status: "bogus"
    }, headers: auth_header

    assert_response :bad_request
  end

  test "create returns 422 with invalid params" do
    post "/pages", params: { title: "" }, headers: auth_header
    assert_response :unprocessable_entity
  end

  test "create with attachment enriches bare sgid with blob attributes" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture("space.jpg").open,
      filename: "space.jpg",
      content_type: "image/jpeg"
    )

    post "/pages", params: {
      title: "Image Page",
      content: %(<p>Hello</p><p><action-text-attachment sgid="#{blob.attachable_sgid}" caption="Page caption"></action-text-attachment></p>),
      status: "published"
    }, headers: auth_header

    assert_response :created
    json = JSON.parse(response.body)
    assert_includes json["content"], 'url="/rails/active_storage/blobs/redirect/'
    assert_includes json["content"], 'caption="Page caption"'
    assert_includes json["content"], 'filename="space.jpg"'
    assert_not_includes json["content"], "<p><action-text-attachment"
    assert_not_includes json["content"], "<figure"
  end

  # -- Update --

  test "update changes page attributes" do
    patch "/pages/#{@page.token}", params: { title: "Updated Page" }, headers: auth_header

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Updated Page", json["title"]
    assert_equal "Updated Page", @page.reload.title
  end

  test "update returns 404 for unknown token" do
    patch "/pages/nonexistent", params: { title: "Nope" }, headers: auth_header
    assert_response :not_found
  end

  # -- Destroy --

  test "destroy discards a page" do
    delete "/pages/#{@page.token}", headers: auth_header

    assert_response :no_content
    assert @page.reload.discarded?
  end

  test "destroy clears home_page_id if destroying the home page" do
    @blog.update!(home_page_id: @page.id)

    delete "/pages/#{@page.token}", headers: auth_header

    assert_response :no_content
    assert_nil @blog.reload.home_page_id
  end

  test "destroy returns 404 for unknown token" do
    delete "/pages/nonexistent", headers: auth_header
    assert_response :not_found
  end

  private

    def auth_header(token = "test_api_key_for_fixtures")
      { "Authorization" => "Bearer #{token}" }
    end
end
