require "test_helper"

class UserTest < ActiveSupport::TestCase

  test "should validate length of username" do
    user = User.new(username: "a" * 21, email: "test@example.com")
    assert_not user.valid?
  end

  test "should validate presence of username" do
    user = User.new(username: "", email: "test@example.com")
    assert_not user.valid?
  end

  test "should validate uniqueness of username" do
    user = User.new(username: users(:joel).username, email: "test@example.com")
    assert_not user.valid?
  end

  test "should validate format of email" do
    user = User.new(username: "newuser", email: "joel")
    assert_not user.valid?

    user = User.new(username: "newuser", email: "joel@blah.blahhhhh")
    assert user.valid?
  end
end
