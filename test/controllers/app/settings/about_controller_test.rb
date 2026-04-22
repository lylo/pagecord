require "test_helper"

class App::Settings::AboutControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    login_as @user
  end

  test "should get index" do
    get app_settings_about_index_url

    assert_select "h3", { count: 1, text: "Bio" }
    assert_select "h3", { count: 1, text: "Title" }
    assert_response :success
  end

  test "should show avatar section if subscribed" do
    get app_settings_about_index_url

    assert_select "h3", { count: 1, text: "Avatar" }
    assert_response :success
  end

  test "should disable avatar section if not subscribed and not on trial" do
    login_as users(:vivian)

    get app_settings_about_index_url

    assert_select "h3", { count: 1, text: "Avatar" }
    assert_select ".opacity-50.pointer-events-none", count: 1
    assert_response :success
  end

  test "should update blog bio" do
    patch app_settings_about_url(@blog), params: { blog: { bio: "New bio" } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal "New bio", @blog.reload.bio.to_plain_text
  end

  test "should update blog title" do
    patch app_settings_about_url(@blog), params: { blog: { title: "New Title" } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_equal "New Title", @blog.reload.title
  end

  test "should update avatar if subscribed" do
    file = fixture_file_upload("avatar.png", "image/png")
    patch app_settings_about_url(@blog), params: { blog: { avatar: file } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert @blog.reload.avatar.attached?
  end

  test "should not update avatar if not subscribed" do
    login_as users(:vivian)
    non_subscribed_blog = users(:vivian).blog

    file = fixture_file_upload("avatar.png", "image/png")
    patch app_settings_about_url(non_subscribed_blog), params: { blog: { avatar: file } }, as: :turbo_stream

    assert_redirected_to app_settings_url
    assert_not non_subscribed_blog.reload.avatar.attached?
  end
end
