require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should validate length of username" do
    user = User.new(username: "a" * 21, email: "test@example.com")
    assert_not user.valid?

    user = User.new(username: "a", email: "test@example.com")
    assert_not user.valid?

    user = User.new(username: "aaaa", email: "test@example.com")
    assert user.valid?
  end

  test "should validate presence of username" do
    user = User.new(username: "", email: "test@example.com")
    assert_not user.valid?
  end

  test "should validate uniqueness of username" do
    user = User.new(username: users(:joel).username, email: "test@example.com")
    assert_not user.valid?
  end

  test "should validate format of username" do
    assert_not User.new(username: "abcdef-", email: "test@example.com").valid?
    assert_not User.new(username: "%12312", email: "test@example.com").valid?
    assert User.new(username: "abcdef_1234", email: "test@example.com").valid?
  end

  test "should validate format of email" do
    user = User.new(username: "newuser", email: "joel")
    assert_not user.valid?

    user = User.new(username: "newuser", email: "joel@blah.blahhhhh")
    assert user.valid?
  end

  test "should store in lowercase" do
    user = User.create!(username: "NewUser", email: "nEwUser@NewUser.COM")
    assert_equal "newuser", user.username
    assert_equal "newuser@newuser.com", user.email
  end

  test "should strip whitespace" do
    user = User.create!(username: "newuser ", email: "newuser@newuser.com")
    assert_equal "newuser", user.username
    assert_equal "newuser@newuser.com", user.email
  end
end
