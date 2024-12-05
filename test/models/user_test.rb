require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should validate format of email" do
    user = User.new(email: "joel")
    assert_not user.valid?

    user = User.new(email: "joel@blah.blahhhhh")
    assert user.valid?
  end

  test "should store in lowercase" do
    user = User.create!(email: "nEwUser@NewUser.COM")
    assert_equal "newuser@newuser.com", user.email
  end

  test "should strip whitespace" do
    user = User.create!(email: "newuser@newuser.com ")
    assert_equal "newuser@newuser.com", user.email
  end
end
