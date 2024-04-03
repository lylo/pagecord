require "test_helper"

class App::FollowingsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user1 = users(:joel)
    @user2 = users(:vivian)

    login_as @user1
  end

  test "should follow a user" do
    assert_difference('@user1.followees.count', 1) do
      post app_user_follow_path(@user2), xhr: true
    end

    assert_response :success
    assert_match "Unfollow", @response.body
    assert @user1.following?(@user2)
  end

  test "should unfollow a user" do
    @user1.follow(@user2)

    assert_difference('@user1.followees.count', -1) do
      delete app_user_unfollow_path(@user2), xhr: true
    end

    assert_response :success
    assert_match "Follow", @response.body
    refute @user1.following?(@user2)
  end

  test "should not follow oneself" do
    assert_no_difference('@user1.followees.count') do
      post app_user_follow_path(@user1), xhr: true
    end

    assert_response :bad_request
    refute @user1.following?(@user1)
  end

  test "should not follow twice" do
    @user1.follow(@user2)

    assert_no_difference('@user1.followees.count') do
      post app_user_follow_path(@user2), xhr: true
    end

    assert_response :bad_request
    assert @user1.following?(@user2)
  end

  test "should bad unfollow" do
    assert_no_difference('@user1.followees.count') do
      delete app_user_unfollow_path(@user2), xhr: true
    end

    assert_response :bad_request
    refute @user1.following?(@user2)
  end
end
