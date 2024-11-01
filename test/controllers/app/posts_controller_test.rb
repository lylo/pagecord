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

  test "should show edit post page" do
    get edit_app_post_url(@user.posts.first)
    assert_response :success
  end

  test "should update post" do
    patch app_post_url(@user.posts.first), params: {
      post: { title: "New Title", content: "New content", published_at: 1.month.ago.to_date }
    }

    assert_redirected_to app_posts_url
    assert_equal "New Title", @user.posts.first.title
    assert_equal "New content", @user.posts.first.content.to_s.strip
    assert_equal 1.month.ago.to_date, @user.posts.first.published_at
  end

  test "app area should be inaccessible on custom domain" do
    post = posts(:four)
    login_as post.user

    get app_posts_url, headers: { 'HOST' => post.user.custom_domain }

    assert_redirected_to root_url
  end
end