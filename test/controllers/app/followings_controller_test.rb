require "test_helper"

class App::FollowingsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @joel = users(:joel)
    @vivian = users(:vivian)

    login_as @vivian
  end

  test "should follow a user" do
    assert_difference("@vivian.followees.count", 1) do
      post app_user_follow_path(@joel), xhr: true
    end

    assert_response :success
    assert_match "Unfollow", @response.body
    assert @vivian.following?(@joel)
  end

  test "should unfollow a user" do
    @vivian.follow(@joel)

    assert_difference("@vivian.followees.count", -1) do
      delete app_user_unfollow_path(@joel), xhr: true
    end

    assert_response :success
    assert_match "Follow", @response.body
    assert_not @vivian.following?(@joel)
  end

  test "should not follow oneself" do
    assert_no_difference("@joel.followees.count") do
      post app_user_follow_path(@vivian), xhr: true
    end

    assert_response :bad_request
    assert_not @vivian.following?(@vivian)
  end

  test "should not follow twice" do
    @vivian.follow(@joel)

    assert_no_difference("@joel.followees.count") do
      post app_user_follow_path(@joel), xhr: true
    end

    assert_response :bad_request
    assert @vivian.following?(@joel)
  end

  test "should return bad request when unfollowing not followed" do
    assert_no_difference("@joel.followees.count") do
      delete app_user_unfollow_path(@joel), xhr: true
    end

    assert_response :bad_request
    assert_not @vivian.following?(@joel)
  end
end
