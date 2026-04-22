require "test_helper"

class Api::HomePagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "api.example.com"

    @blog = blogs(:joel)
    @user = users(:joel)
    @user.update!(trial_ends_at: 30.days.from_now)
  end

  # -- Show --

  test "show returns the home page" do
    page = posts(:about)
    @blog.update!(home_page_id: page.id)

    get "/home_page", headers: auth_header

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal page.title, json["title"]
    assert_equal true, json["is_page"]
    assert_equal true, json["is_home_page"]
  end

  test "show returns 404 when no home page is set" do
    @blog.update!(home_page_id: nil)

    get "/home_page", headers: auth_header
    assert_response :not_found
  end

  # -- Create --

  test "create makes a new home page" do
    assert_difference "Post.count" do
      post "/home_page", params: {
        title: "Welcome", content: "<p>Welcome home</p>", status: "published"
      }, headers: auth_header
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Welcome", json["title"]
    assert_equal true, json["is_page"]
    assert_equal true, json["is_home_page"]
    created = Post.find_by(token: json["token"])
    assert created.is_page?
    assert_equal @blog.reload.home_page_id, created.id
  end

  test "create converts markdown" do
    post "/home_page", params: {
      content: "# Welcome\nHello **world**", content_format: "markdown", status: "published"
    }, headers: auth_header

    assert_response :created
    json = JSON.parse(response.body)
    assert_includes json["content"], "<strong>world</strong>"
  end

  test "create returns 422 when home page already exists" do
    @blog.update!(home_page_id: posts(:about).id)

    assert_no_difference "Post.count" do
      post "/home_page", params: {
        title: "Another", content: "<p>Nope</p>", status: "published"
      }, headers: auth_header
    end

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["errors"], "Home page already exists"
  end

  test "create returns 422 with invalid params" do
    post "/home_page", params: { title: "" }, headers: auth_header
    assert_response :unprocessable_entity
  end

  test "create with attachment enriches bare sgid with blob attributes" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture("space.jpg").open,
      filename: "space.jpg",
      content_type: "image/jpeg"
    )

    post "/home_page", params: {
      content: %(<p>Welcome</p><p><action-text-attachment sgid="#{blob.attachable_sgid}" caption="Home caption"></action-text-attachment></p>),
      status: "published"
    }, headers: auth_header

    assert_response :created
    json = JSON.parse(response.body)
    assert_includes json["content"], 'url="/rails/active_storage/blobs/redirect/'
    assert_includes json["content"], 'caption="Home caption"'
    assert_includes json["content"], 'filename="space.jpg"'
    assert_not_includes json["content"], "<p><action-text-attachment"
    assert_not_includes json["content"], "<figure"
  end

  # -- Update --

  test "update changes home page attributes" do
    page = posts(:about)
    @blog.update!(home_page_id: page.id)

    patch "/home_page", params: { title: "Updated Home" }, headers: auth_header

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "Updated Home", json["title"]
    assert_equal "Updated Home", page.reload.title
  end

  test "update returns 404 when no home page is set" do
    @blog.update!(home_page_id: nil)

    patch "/home_page", params: { title: "Nope" }, headers: auth_header
    assert_response :not_found
  end

  # -- Destroy --

  test "destroy unlinks the home page but keeps the page" do
    page = posts(:about)
    @blog.update!(home_page_id: page.id)

    delete "/home_page", headers: auth_header

    assert_response :no_content
    assert_nil @blog.reload.home_page_id
    assert_not page.reload.discarded?
  end

  test "destroy gives a blank-titled home page a default title" do
    page = posts(:about)
    page.update_columns(title: "")
    @blog.update!(home_page_id: page.id)

    delete "/home_page", headers: auth_header

    assert_response :no_content
    assert_equal "Home Page", page.reload.title
  end

  test "destroy returns 404 when no home page is set" do
    @blog.update!(home_page_id: nil)

    delete "/home_page", headers: auth_header
    assert_response :not_found
  end

  private

    def auth_header(token = "test_api_key_for_fixtures")
      { "Authorization" => "Bearer #{token}" }
    end
end
