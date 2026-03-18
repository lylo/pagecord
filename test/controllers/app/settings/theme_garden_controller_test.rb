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

  test "should show active templates only" do
    get app_settings_theme_garden_index_url

    assert_select "h3", text: "Minimal Mono"
    assert_select "h3", text: "Bold Serif"
    assert_select "h3", { count: 0, text: "Inactive Template" }
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
    assert_equal ".blog { font-size: 0.75rem; }", @blog.custom_css
    assert_equal "mono", @blog.font
    assert_equal "narrow", @blog.width
    assert_equal "title_layout", @blog.layout
  end

  test "apply should not change settings that template leaves nil" do
    original_theme = @blog.theme
    original_layout = @blog.layout

    post apply_app_settings_theme_garden_url(theme_templates(:bold_serif))

    @blog.reload
    assert_equal "coral", @blog.theme
    assert_equal "serif", @blog.font
    assert_equal original_layout, @blog.layout
  end

  test "apply should reject non-premium users" do
    login_as users(:vivian)

    post apply_app_settings_theme_garden_url(@template)

    assert_redirected_to app_settings_theme_garden_index_path
    assert_not_equal ".blog { font-size: 0.75rem; }", users(:vivian).blog.reload.custom_css
  end

  test "preview should not find inactive templates" do
    get preview_app_settings_theme_garden_url(theme_templates(:inactive_template))

    assert_response :not_found
  end
end
