require "test_helper"

class App::Settings::ThemeGardenControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    @template = theme_templates(:minimal_mono)
    login_as @user
  end

  test "should get index" do
    get app_settings_theme_garden_index_url

    assert_response :success
    assert_select "h2", text: "Theme Garden"
  end

  test "should show active templates" do
    get app_settings_theme_garden_index_url

    assert_select "h3", text: "Minimal Mono"
  end

  test "should show subscribe callout for free users" do
    login_as users(:vivian)

    get app_settings_theme_garden_index_url

    assert_response :success
    assert_select "a", text: "Subscribe"
  end

  test "should not show apply buttons for free users" do
    login_as users(:vivian)

    get app_settings_theme_garden_index_url

    assert_select "button", { count: 0, text: "Apply" }
  end

  test "preview should render blog layout with template styling" do
    get preview_app_settings_theme_garden_url(@template)

    assert_response :success
  end

  test "apply should update blog with template attributes" do
    post apply_app_settings_theme_garden_url(@template)

    assert_redirected_to app_settings_appearance_index_path
    @blog.reload
    assert_includes @blog.custom_css, "12px monospace journal"
    assert_equal "mono", @blog.font
    assert_equal "narrow", @blog.width
    assert_equal "stream_layout", @blog.layout
    assert_equal "base", @blog.theme
  end

  test "apply should reject non-premium users" do
    login_as users(:vivian)

    post apply_app_settings_theme_garden_url(@template)

    assert_redirected_to app_settings_theme_garden_index_path
  end
end
