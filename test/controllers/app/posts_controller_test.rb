require "test_helper"

class App::PostsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
  end

  test "should get root" do
    get app_root_url
    assert_response :success
  end

  test "should get posts index" do
    get app_posts_url
    assert_response :success
  end

  test "should destroy post" do
    assert_difference("@user.posts.count", -1) do
      delete app_post_url(@user.posts.first)
    end
    assert_redirected_to app_posts_url
  end

  test "app area should be inaccessible on custom domain" do
    post = posts(:four)
    login_as post.user

    get app_posts_url, headers: { 'HOST' => post.user.custom_domain }

    assert_redirected_to root_url
  end
end