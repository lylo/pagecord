require "test_helper"

class App::Settings::CustomCode::PreviewsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    login_as @user
  end

  test "should render the blog with the candidate CSS" do
    preview ".blog { color: rebeccapurple; }"

    assert_response :success
    assert_includes response.body, "rebeccapurple"
  end

  test "should not save the candidate CSS" do
    @blog.update!(custom_css: ".blog { color: red; }")

    preview ".blog { color: rebeccapurple; }"

    assert_response :success
    assert_equal ".blog { color: red; }", @blog.reload.custom_css
  end

  test "should not run custom head or body code in a preview" do
    @blog.update!(custom_head_html: '<meta name="preview-canary" content="1">')

    preview ".blog { color: red; }"

    assert_response :success
    assert_not_includes response.body, "preview-canary"
  end

  test "should preview the custom home page when the blog has one" do
    home_page = posts(:about)
    @blog.update!(home_page_id: home_page.id)

    preview ".blog { color: rebeccapurple; }"

    assert_response :success
    assert_includes response.body, "rebeccapurple"
    assert_includes response.body, home_page.title
  end

  test "should send a reloaded preview back to the settings page" do
    get app_settings_custom_code_preview_url

    assert_redirected_to app_settings_custom_code_path
  end

  test "should be reachable by the method the Custom code form actually sends" do
    get app_settings_custom_code_url
    assert_response :success

    form_action = css_select("input[value=Preview]").first["formaction"]
    assert_equal app_settings_custom_code_preview_path, form_action

    patch form_action, params: { blog: { custom_css: ".blog { color: rebeccapurple; }" } }

    assert_response :success
    assert_includes response.body, "rebeccapurple"
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

  private

    def preview(css)
      patch app_settings_custom_code_preview_url, params: { blog: { custom_css: css } }
    end
end
