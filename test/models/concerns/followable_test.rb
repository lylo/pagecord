require "test_helper"

class FollowableTest < ActiveSupport::TestCase
  def setup
    @user1 = users(:joel)
    @user2 = users(:elliot)
  end

  test "should allow a user to follow another user" do
    @user1.follow @user2.blog
    assert @user1.followed_blogs.include?(@user2.blog)
  end

  test "should not allow a user to follow themselves" do
    assert_raises ArgumentError do
      @user1.follow @user1.blog
    end
  end

  test "should not allow a user to follow a user they are already following" do
    @user1.follow @user2.blog

    assert_raises ArgumentError do
      @user1.follow @user2.blog
    end
  end

  test "should allow a user to unfollow another user" do
    @user1.follow @user2.blog
    @user1.unfollow @user2.blog

    assert_not @user1.followed_blogs.include?(@user2.blog)
  end

  test "should not allow a user to unfollow a user they are not following" do
    assert_raises ArgumentError do
      @user1.unfollow @user2.blog
    end
  end

  test "should return true if the user is following the other user" do
    @user1.follow @user2.blog
    assert @user1.following?(@user2.blog)
  end

  test "should return false if the user is not following the other user" do
    assert_not @user1.following?(@user2.blog)
  end
end
