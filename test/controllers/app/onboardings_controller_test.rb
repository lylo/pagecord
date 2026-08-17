require "test_helper"

class App::OnboardingsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:saul)
    login_as @user
  end

  test "should be redirect to onboarding page" do
    get app_root_path

    assert_redirected_to app_onboarding_path
  end

  test "should render onboarding page with theme tabs" do
    get app_onboarding_path

    assert_response :success
    assert_select "[data-controller=tabs]"
    assert_select "a", text: "Browse all designs in the Theme Garden"
  end

  test "should update blog title" do
    patch app_onboarding_path, params: { blog: { title: "New Title" } }, as: :turbo_stream

    assert_response :success
    assert_equal "New Title", @user.blog.reload.title
    assert_select "turbo-stream[target=heading_blog_title]", text: "New Title"
  end

  test "should update bio" do
    patch app_onboarding_path, params: { blog: { bio: "New Bio" } }, as: :turbo_stream

    assert_response :success
    assert_equal "New Bio", @user.blog.reload.bio.to_plain_text
  end

  test "should select title layout" do
    patch app_onboarding_path, params: { blog: { layout: "title_layout" } }, as: :turbo_stream

    assert_response :success
    assert_equal "title_layout", @user.blog.reload.layout
  end

  test "should apply a theme template" do
    template = theme_templates(:minimal_mono)

    post apply_theme_app_onboarding_path, params: { template_id: template.id }, as: :turbo_stream

    assert_response :no_content
    @blog = @user.blog.reload
    assert_includes @blog.custom_css, "12px monospace journal"
    assert_equal "mono", @blog.font
    assert_equal "narrow", @blog.width
    assert_equal "stream_layout", @blog.layout
  end

  test "should complete onboarding" do
    post complete_app_onboarding_path

    assert_redirected_to app_root_path
    assert_equal "Welcome to Pagecord!", flash[:notice]
    assert @user.reload.onboarding_complete?
  end
end
