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

  test "should complete onboarding" do
    post complete_app_onboarding_path

    assert_redirected_to app_root_path
    assert_equal "Welcome to Pagecord!", flash[:notice]
    assert @user.reload.onboarding_complete?
  end
end
