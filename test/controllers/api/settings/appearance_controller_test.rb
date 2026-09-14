require "test_helper"

class Api::Settings::AppearanceControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "api.example.com"

    @blog = blogs(:joel)
    @user = users(:joel)
  end

  # -- Show --

  test "show returns the appearance settings" do
    get "/settings/appearance", headers: auth_header

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @blog.theme, json["theme"]
    assert_equal "stream_layout", json["layout"]
    assert json.key?("updated_at")
  end

  test "show returns unauthorized without a token" do
    get "/settings/appearance"
    assert_response :unauthorized
  end

  test "show returns forbidden without premium access" do
    @user.subscription.destroy!
    @user.update!(trial_ends_at: nil)

    get "/settings/appearance", headers: auth_header
    assert_response :forbidden
  end

  # -- Update --

  test "update only changes the attributes it is given" do
    @blog.update!(theme: "base", font: "serif")

    patch "/settings/appearance", params: { theme: "sand" }, headers: auth_header

    assert_response :success
    assert_equal "sand", @blog.reload.theme
    assert_equal "serif", @blog.font
  end

  test "update rejects an invalid theme" do
    patch "/settings/appearance", params: { theme: "neon" }, headers: auth_header

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["errors"], "Theme neon is not a valid theme"
  end

  test "update rejects an invalid layout" do
    patch "/settings/appearance", params: { layout: "sideways" }, headers: auth_header

    assert_response :unprocessable_entity
    assert_equal "stream_layout", @blog.reload.layout
  end

  test "update sets a valid layout" do
    patch "/settings/appearance", params: { layout: "cards_layout" }, headers: auth_header

    assert_response :success
    assert_equal "cards_layout", @blog.reload.layout
  end

  test "update sets show branding for a subscriber" do
    patch "/settings/appearance", params: { show_branding: false }, headers: auth_header

    assert_response :success
    assert_not @blog.reload.show_branding
  end

  test "update rejects show branding on trial" do
    @user.subscription.destroy!
    @user.update!(trial_ends_at: 30.days.from_now)

    patch "/settings/appearance", params: { show_branding: false }, headers: auth_header

    assert_response :forbidden
    assert_equal "show_branding requires a subscription", JSON.parse(response.body)["error"]
    assert @blog.reload.show_branding
  end

  test "update allows other attributes on trial" do
    @user.subscription.destroy!
    @user.update!(trial_ends_at: 30.days.from_now)

    patch "/settings/appearance", params: { theme: "sand" }, headers: auth_header

    assert_response :success
    assert_equal "sand", @blog.reload.theme
  end

  private

    def auth_header(token = "test_api_key_for_fixtures")
      { "Authorization" => "Bearer #{token}" }
    end
end
