require "test_helper"

class App::Settings::ThemeGardenControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    @template = theme_templates(:minimal_mono)
    login_as @user
  end

  test "should show active templates" do
    get app_settings_theme_garden_index_url

    assert_select "h4", text: "Minimal Mono"
  end

  test "should show apply buttons for free users" do
    login_as users(:vivian)

    get app_settings_theme_garden_index_url

    assert_response :success
    assert_select "button", text: "Apply"
  end

  test "preview should render blog layout with template styling" do
    get app_settings_theme_garden_preview_url(@template)

    assert_response :success
  end

  test "apply should update blog with template attributes" do
    post app_settings_theme_garden_application_url(@template)

    assert_redirected_to app_settings_appearance_path
    @blog.reload
    assert_equal @template, @blog.theme_template
    assert_nil @blog.custom_css
    assert_equal "mono", @blog.font
    assert_equal "narrow", @blog.width
    assert_equal "stream_layout", @blog.layout
    assert_equal "base", @blog.theme
  end

  test "classic is offered and puts a blog back on its own settings" do
    @blog.apply_design(@template)

    get app_settings_theme_garden_index_url
    assert_select "div.ring-pagecord-accent h4", text: "Minimal Mono"
    assert_select "form[action=?]", app_settings_theme_garden_application_path("classic")

    post app_settings_theme_garden_application_url("classic")

    assert_redirected_to app_settings_appearance_path
    @blog.reload
    assert_nil @blog.theme_template
    assert_equal "sans", @blog.font
  end

  test "apply should work for free users" do
    login_as users(:vivian)

    post app_settings_theme_garden_application_url(@template)

    assert_redirected_to app_settings_appearance_path
  end
end
