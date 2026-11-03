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

  test "previews classic" do
    @blog.apply_design(@template)

    get app_settings_theme_garden_preview_url("classic")

    assert_response :success
    assert_select "link[href*='themes/']", count: 0
  end

  test "always asks before replacing appearance settings" do
    get app_settings_theme_garden_index_url

    assert_select "form[data-turbo-confirm*='replaces your colour scheme']"
  end

  test "keeps offering a design the blog uses after it is retired from the garden" do
    @blog.apply_design(@template)
    @template.update!(active: false)

    get app_settings_theme_garden_index_url
    assert_select "div.ring-pagecord-accent h4", text: "Minimal Mono"

    post app_settings_theme_garden_application_url(@template)
    assert_redirected_to app_settings_appearance_path

    post app_settings_theme_garden_application_url(theme_templates(:novella))
    post app_settings_theme_garden_application_url(@template)
    assert_response :not_found
    assert_equal theme_templates(:novella), @blog.reload.theme_template
  end

  test "does not apply a retired design the blog doesn't use" do
    @template.update!(active: false)

    post app_settings_theme_garden_application_url(@template)

    assert_response :not_found
  end

  test "apply should work for free users" do
    login_as users(:vivian)

    post app_settings_theme_garden_application_url(@template)

    assert_redirected_to app_settings_appearance_path
  end
end
