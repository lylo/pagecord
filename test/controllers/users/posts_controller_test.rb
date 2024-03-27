require "test_helper"

class Users::PostsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get user_posts_path(username: users(:joel).username)

    assert_response :success
    assert_not_nil assigns(:posts)
  end

  test "should get show" do
    get post_path(posts(:one))
    assert_response :success
    assert_equal posts(:one), assigns(:post)
  end

  test "should allow @ prefix and redirect to user" do
    get "/@#{users(:joel).username}"
    assert_redirected_to user_posts_path(username: users(:joel).username)
  end

  test "should redirect to root if user not found" do
    get user_posts_path(username: "nope")
    assert_redirected_to root_url
    assert_equal "User not found", flash[:alert]
  end

  test "should redirect to root if user is unverified" do
    get user_posts_path(username: users(:elliot).username)
    assert_redirected_to root_url
  end

  test "should get index as RSS" do
    get user_posts_path(username: users(:joel).username, format: :rss)

    assert_response :success
    assert_equal "application/rss+xml; charset=utf-8", @response.content_type
  end
end
