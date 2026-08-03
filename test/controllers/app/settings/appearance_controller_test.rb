require "test_helper"

class App::Settings::AppearanceControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    login_as @user
  end

  test "should get index" do
    get app_settings_appearance_index_url

    assert_select "h3", { count: 1, text: "Finer Details" }
    assert_select "h4", { count: 1, text: "Font" }
    assert_select "h4", { count: 1, text: "Blog Layout" }
    assert_response :success
  end

  test "index tabs the colour scheme against ready-made designs" do
    get app_settings_appearance_index_url

    assert_response :success
    assert_select "[data-controller=tabs] button[data-tabs-target=tab]", count: 2
    assert_select "a[href=?]", app_settings_theme_garden_index_path
    ThemeTemplate.active.ordered.first.tap do |template|
      assert_select "form[action=?]", apply_app_settings_theme_garden_path(template)
      assert_select "a[href=?]", preview_app_settings_theme_garden_path(template)
    end
  end

  test "should update blog layout" do
    patch app_settings_appearance_url(@blog), params: { blog: { layout: "title_layout" } }, as: :turbo_stream

    assert_response :success
    assert_equal "title_layout", @blog.reload.layout
  end

  test "should update show branding flag for subscriber" do
    patch app_settings_appearance_url(@blog), params: { blog: { show_branding: false } }, as: :turbo_stream

    assert_response :success
    assert_not @blog.reload.show_branding
  end

  test "should not update show branding flag for non-subscriber" do
    @user = users(:vivian)
    login_as @user
    @blog = @user.blog

    patch app_settings_appearance_url(@blog), params: { blog: { show_branding: false } }, as: :turbo_stream

    assert_response :success
    assert @blog.reload.show_branding
  end

  test "points custom css and footer at the custom code page" do
    get app_settings_appearance_index_url
    assert_select "h3", { count: 0, text: "Advanced" }
    assert_response :success
    assert_select "textarea#blog_custom_css", false
    assert_select "a[href=?]", app_settings_custom_code_path

    patch app_settings_appearance_url(@blog), params: { blog: { custom_css: ".blog { color: red; }" } }, as: :turbo_stream
    assert_response :success
    assert_nil @blog.reload.custom_css
  end

  test "should update custom theme colors" do
    patch app_settings_appearance_url(@blog), params: {
      blog: {
        custom_theme_bg_light: "#111111",
        custom_theme_text_light: "#222222",
        custom_theme_accent_light: "#333333",
        custom_theme_bg_dark: "#444444",
        custom_theme_text_dark: "#555555",
        custom_theme_accent_dark: "#666666"
      }
    }, as: :turbo_stream

    assert_response :success
    @blog.reload
    assert_equal "#111111", @blog.custom_theme_bg_light
    assert_equal "#222222", @blog.custom_theme_text_light
    assert_equal "#333333", @blog.custom_theme_accent_light
    assert_equal "#444444", @blog.custom_theme_bg_dark
    assert_equal "#555555", @blog.custom_theme_text_dark
    assert_equal "#666666", @blog.custom_theme_accent_dark
  end
end
