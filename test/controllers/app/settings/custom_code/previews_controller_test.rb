require "test_helper"

class App::Settings::CustomCode::PreviewsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    login_as @user
    Rails.stubs(:cache).returns(ActiveSupport::Cache::MemoryStore.new)
    SecureRandom.stubs(:base58).returns("abc123")
  end

  test "should stash the candidate CSS and send the tab to the blog" do
    patch app_settings_custom_code_preview_url, params: { blog: { custom_css: ".blog { color: rebeccapurple; }" } }

    assert_redirected_to blog_css_preview_url("abc123", host: @blog.host)
    assert_includes Rails.cache.read("css_preview:#{@blog.id}:abc123"), "rebeccapurple"
  end

  test "should stash the CSS sanitised" do
    patch app_settings_custom_code_preview_url, params: { blog: { custom_css: ".blog { background: url(javascript:alert(1)); color: rebeccapurple; }" } }

    stashed = Rails.cache.read("css_preview:#{@blog.id}:abc123")
    assert_includes stashed, "rebeccapurple"
    assert_not_includes stashed, "javascript:"
  end

  test "should not save the candidate CSS" do
    @blog.update!(custom_css: ".blog { color: red; }")

    patch app_settings_custom_code_preview_url, params: { blog: { custom_css: ".blog { color: rebeccapurple; }" } }

    assert_equal ".blog { color: red; }", @blog.reload.custom_css
  end

  test "should be reachable by the method the Custom code form actually sends" do
    get app_settings_custom_code_url
    assert_response :success

    form_action = css_select("input[value=Preview]").first["formaction"]
    assert_equal app_settings_custom_code_preview_path, form_action

    patch form_action, params: { blog: { custom_css: ".blog { color: rebeccapurple; }" } }

    assert_response :redirect
  end

  test "should not offer a preview on the other code fields" do
    get app_settings_custom_code_url

    assert_equal 1, css_select("input[value=Preview]").size
  end

  test "should require a login" do
    logout

    patch app_settings_custom_code_preview_url, params: { blog: { custom_css: ".blog { color: red; }" } }

    assert_redirected_to login_url
  end
end
