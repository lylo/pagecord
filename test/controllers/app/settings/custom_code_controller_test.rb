require "test_helper"

class App::Settings::CustomCodeControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    login_as @user
  end

  test "should show every code field for a subscriber" do
    get app_settings_custom_code_url

    assert_response :success
    assert_select "textarea#blog_custom_css"
    assert_select "textarea#blog_custom_footer_html"
    assert_select "textarea#blog_custom_head_html:not([disabled])"
    assert_select "textarea#blog_custom_body_html:not([disabled])"
  end

  test "should show css and footer but disable code for a trialist" do
    trialist = users(:vivian)
    trialist.update!(trial_ends_at: 1.week.from_now, features: [ "custom_code" ])
    login_as trialist

    get app_settings_custom_code_url

    assert_response :success
    assert_select "textarea#blog_custom_css"
    assert_select "textarea#blog_custom_head_html[disabled]"
    assert_select "a[href=?]", app_settings_subscriptions_path
  end

  test "should show every field disabled on the free plan" do
    login_as users(:vivian)

    get app_settings_custom_code_url

    assert_response :success
    assert_select "textarea#blog_custom_css[disabled]"
    assert_select "textarea#blog_custom_footer_html[disabled]"
    assert_select "a[href=?]", app_settings_subscriptions_path
  end

  test "should not update custom css on the free plan" do
    free_user = users(:vivian)
    login_as free_user

    patch app_settings_custom_code_url, params: { blog: { custom_css: ".blog { color: red; }" } }, as: :turbo_stream

    assert_response :success
    assert_nil free_user.blog.reload.custom_css
  end

  test "should not update custom footer on the free plan" do
    free_user = users(:vivian)
    login_as free_user

    patch app_settings_custom_code_url, params: { blog: { custom_footer_html: "<p>hi</p>" } }, as: :turbo_stream

    assert_response :success
    assert_nil free_user.blog.reload.custom_footer_html
  end

  test "should hide head and body code without the feature flag" do
    @user.update!(features: [])

    get app_settings_custom_code_url

    assert_response :success
    assert_select "textarea#blog_custom_css"
    assert_select "textarea#blog_custom_head_html", false
  end

  test "should update custom css" do
    custom_css = ".blog { background: red; }"

    patch app_settings_custom_code_url, params: { blog: { custom_css: custom_css } }, as: :turbo_stream

    assert_response :success
    assert_equal custom_css, @blog.reload.custom_css
  end

  test "should update custom footer" do
    footer = '<a href="https://example.com" target="_blank">Example</a>'

    patch app_settings_custom_code_url, params: { blog: { custom_footer_html: footer } }, as: :turbo_stream

    assert_response :success
    assert_equal footer, @blog.reload.custom_footer_html
  end

  test "should update custom code for a subscriber" do
    patch app_settings_custom_code_url, params: { blog: {
      custom_head_html: '<script src="https://plausible.io/js/script.js"></script>',
      custom_body_html: '<div id="chat"></div>',
      custom_code_enabled: "0"
    } }, as: :turbo_stream

    assert_response :success
    @blog.reload
    assert_equal '<script src="https://plausible.io/js/script.js"></script>', @blog.custom_head_html
    assert_equal '<div id="chat"></div>', @blog.custom_body_html
    assert_not @blog.custom_code_enabled
  end

  test "should not update custom code for a trialist" do
    trialist = users(:vivian)
    trialist.update!(trial_ends_at: 1.week.from_now, features: [ "custom_code" ])
    login_as trialist

    patch app_settings_custom_code_url, params: { blog: { custom_head_html: '<script src="/evil.js"></script>' } }, as: :turbo_stream

    assert_response :success
    assert_nil trialist.blog.reload.custom_head_html
  end

  test "should not update custom code without the feature flag" do
    @user.update!(features: [])

    patch app_settings_custom_code_url, params: { blog: { custom_head_html: '<script src="/a.js"></script>' } }, as: :turbo_stream

    assert_response :success
    assert_nil @blog.reload.custom_head_html
  end

  test "should show validation error for markup that does not belong in head" do
    patch app_settings_custom_code_url, params: { blog: { custom_head_html: '<div id="widget"></div>' } }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_match "&lt;div&gt;", response.body
    assert_nil @blog.reload.custom_head_html
  end

  test "should show validation error for malicious custom css" do
    patch app_settings_custom_code_url, params: { blog: { custom_css: ".blog { color: red; }</style><script>alert(1)</script>" } }, as: :turbo_stream

    assert_response :unprocessable_entity
    assert_nil @blog.reload.custom_css
  end
end
