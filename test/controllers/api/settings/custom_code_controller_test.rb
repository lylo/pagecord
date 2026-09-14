require "test_helper"

class Api::Settings::CustomCodeControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "api.example.com"

    @blog = blogs(:joel)
    @user = users(:joel)
  end

  # -- Show --

  test "show returns the custom code settings" do
    @blog.update!(custom_css: "body { color: red }")

    get "/settings/custom_code", headers: auth_header

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "body { color: red }", json["custom_css"]
    assert json.key?("custom_head_html")
    assert json.key?("updated_at")
  end

  test "show returns unauthorized without a token" do
    get "/settings/custom_code"
    assert_response :unauthorized
  end

  test "show returns forbidden without premium access" do
    @user.subscription.destroy!
    @user.update!(trial_ends_at: nil)

    get "/settings/custom_code", headers: auth_header
    assert_response :forbidden
  end

  # -- Update --

  test "update only changes the attributes it is given" do
    @blog.update!(custom_css: "body { color: red }", custom_footer_html: "<p>Bye</p>")

    patch "/settings/custom_code", params: { custom_css: "body { color: blue }" }, headers: auth_header

    assert_response :success
    assert_equal "body { color: blue }", @blog.reload.custom_css
    assert_equal "<p>Bye</p>", @blog.custom_footer_html
  end

  test "update rejects unsafe custom CSS" do
    patch "/settings/custom_code",
      params: { custom_css: ".blog { color: red; }</style><script>alert(1)</script>" },
      headers: auth_header

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["errors"], "Custom css contains invalid or potentially unsafe content"
  end

  test "update sets custom head html for a subscriber" do
    patch "/settings/custom_code",
      params: { custom_head_html: "<meta name=\"x\" content=\"y\">" },
      headers: auth_header

    assert_response :success
    assert_equal "<meta name=\"x\" content=\"y\">", @blog.reload.custom_head_html
  end

  test "update sets custom code enabled for a subscriber" do
    patch "/settings/custom_code", params: { custom_code_enabled: false }, headers: auth_header

    assert_response :success
    assert_not @blog.reload.custom_code_enabled
  end

  test "update rejects custom head html on trial" do
    @user.subscription.destroy!
    @user.update!(trial_ends_at: 30.days.from_now)

    patch "/settings/custom_code", params: { custom_head_html: "<meta name=\"x\">" }, headers: auth_header

    assert_response :forbidden
    assert_equal "custom_head_html requires a subscription", JSON.parse(response.body)["error"]
    assert_nil @blog.reload.custom_head_html
  end

  test "update allows custom CSS on trial" do
    @user.subscription.destroy!
    @user.update!(trial_ends_at: 30.days.from_now)

    patch "/settings/custom_code", params: { custom_css: "body { color: blue }" }, headers: auth_header

    assert_response :success
    assert_equal "body { color: blue }", @blog.reload.custom_css
  end

  private

    def auth_header(token = "test_api_key_for_fixtures")
      { "Authorization" => "Bearer #{token}" }
    end
end
