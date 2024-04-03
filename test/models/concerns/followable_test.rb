require "test_helper"

class FollowableTest < ActiveSupport::TestCase
  def setup
    @user1 = users(:joel)
    @user2 = users(:elliot)
  end

  test "should allow a user to follow another user" do
    @user1.follow @user2
    assert @user1.followees.include?(@user2)
  end

  test "should not allow a user to follow themselves" do
    assert_raises ArgumentError do
      @user1.follow @user1
    end
  end

  test "should not allow a user to follow a user they are already following" do
    @user1.follow @user2

    assert_raises ArgumentError do
      @user1.follow @user2
    end
  end

  test "should allow a user to unfollow another user" do
    @user1.follow @user2
    @user1.unfollow @user2

    refute @user1.followees.include?(@user2)
  end

  test "should not allow a user to unfollow a user they are not following" do
    assert_raises ArgumentError do
      @user1.unfollow @user2
    end
  end

  test "should return true if the user is following the other user" do
    @user1.follow @user2
    assert @user1.following?(@user2)
  end

  test "should return false if the user is not following the other user" do
    refute @user1.following?(@user2)
  end

  test "should return true if the user is followed by the other user" do
    @user1.follow @user2
    assert @user2.is_followed_by?(@user1)
  end

  test "should return false if the user is not followed by the other user" do
    refute @user2.is_followed_by?(@user1)
  end
end