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

  test "should validate format of email" do
    user = User.new(username: "newuser", email: "joel")
    assert_not user.valid?

    user = User.new(username: "newuser", email: "joel@blah.blahhhhh")
    assert user.valid?
  end

  test "should generate unique delivery email" do
    user = User.create!(username: "newuser", email: "newuser@newuser.com")
    assert user.delivery_email.present?
    assert user.delivery_email =~ /newuser_[a-zA-Z0-9]{8}@post.pagecord.com/
  end

  test "should store in lowercase" do
    user = User.create!(username: "NewUser", email: "nEwUser@NewUser.COM")
    assert_equal "newuser", user.username
    assert_equal "newuser@newuser.com", user.email
  end
end
