require "test_helper"

class UserPasswordTest < ActiveSupport::TestCase
  test "user can be created without password" do
    user = User.create!(email: "test@example.com")
    assert_not user.has_password?
  end

  test "user can be created with password" do
    user = User.create!(email: "test@example.com", password: "password1234", password_confirmation: "password1234")
    assert user.has_password?
  end

  test "password must be at least 12 characters if provided" do
    user = User.new(email: "test@example.com", password: "short", password_confirmation: "short")
    assert_not user.valid?
    assert user.errors[:password].present?
  end

  test "password confirmation must match if password provided" do
    user = User.new(email: "test@example.com", password: "password1234", password_confirmation: "different")
    assert_not user.valid?
  end

  test "can authenticate with correct password" do
    user = User.create!(email: "test@example.com", password: "password1234", password_confirmation: "password1234")
    assert user.authenticate("password1234")
  end

  test "cannot authenticate with incorrect password" do
    user = User.create!(email: "test@example.com", password: "password1234", password_confirmation: "password1234")
    assert_not user.authenticate("wrongpassword")
  end

  test "can update user without changing password" do
    user = User.create!(email: "test@example.com", password: "password1234", password_confirmation: "password1234")
    assert user.update(timezone: "America/New_York")
  end

  test "can add password to existing user" do
    user = User.create!(email: "test@example.com")
    assert_not user.has_password?

    assert user.update(password: "newpassword123", password_confirmation: "newpassword123")
    assert user.has_password?
  end
end
