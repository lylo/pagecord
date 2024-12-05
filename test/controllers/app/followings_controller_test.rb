require "test_helper"

class App::FollowingsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @joel = users(:joel)
    @vivian = users(:vivian)

    login_as @vivian
  end

  test "should follow a blog" do
    assert_difference("@vivian.followees.count", 1) do
      post app_blog_follow_path(@joel.blog), xhr: true
    end

    assert_response :success
    assert_match "Unfollow", @response.body
    assert @vivian.following?(@joel.blog)
  end

  test "should unfollow a blog" do
    @vivian.follow(@joel.blog)

    assert_difference("@vivian.followees.count", -1) do
      delete app_blog_unfollow_path(@joel.blog), xhr: true
    end

    assert_response :success
    assert_match "Follow", @response.body
    assert_not @vivian.following?(@joel.blog)
  end

  test "should not follow oneself" do
    assert_no_difference("@joel.followees.count") do
      post app_blog_follow_path(@vivian.blog), xhr: true
    end

    assert_response :bad_request
    assert_not @vivian.following?(@vivian.blog)
  end

  test "should not follow twice" do
    @vivian.follow(@joel.blog)

    assert_no_difference("@joel.followees.count") do
      post app_blog_follow_path(@joel.blog), xhr: true
    end

    assert_response :bad_request
    assert @vivian.following?(@joel.blog)
  end

  test "should return bad request when unfollowing not followed" do
    assert_no_difference("@joel.followees.count") do
      delete app_blog_unfollow_path(@joel.blog), xhr: true
    end

    assert_response :bad_request
    assert_not @vivian.following?(@joel.blog)
  end
end
