require "test_helper"

class PasswordSecuredTest < ActiveSupport::TestCase
  test "can be created without password" do
    user = User.create!(email: "test@example.com")
    assert_not user.has_password?
  end

  test "can be created with password" do
    user = User.create!(email: "test@example.com", password: "password1234", password_confirmation: "password1234")
    assert user.has_password?
  end

  test "password must be at least 12 characters" do
    user = User.new(email: "test@example.com", password: "short", password_confirmation: "short")
    assert_not user.valid?
    assert user.errors[:password].present?
  end

  test "password longer than bcrypt hashes is rejected" do
    password = "a" * 73
    user = User.new(email: "test@example.com", password: password, password_confirmation: password)

    assert_not user.valid?
    assert user.errors[:password].present?
  end

  # The limit is bcrypt's and it counts bytes, so a password well inside any
  # character count can still cross it.
  test "multibyte password is measured in bytes" do
    password = "é" * 72 # 144 bytes
    user = User.new(email: "test@example.com", password: password, password_confirmation: password)

    assert_not user.valid?
    assert user.errors[:password].present?
  end

  test "password confirmation must match" do
    user = User.new(email: "test@example.com", password: "password1234", password_confirmation: "different")
    assert_not user.valid?
    assert user.errors[:password_confirmation].present?
  end

  test "authenticates with correct password" do
    user = User.create!(email: "test@example.com", password: "password1234", password_confirmation: "password1234")
    assert user.authenticate("password1234")
  end

  test "rejects incorrect password" do
    user = User.create!(email: "test@example.com", password: "password1234", password_confirmation: "password1234")
    assert_not user.authenticate("wrongpassword")
  end

  test "can update without changing password" do
    user = User.create!(email: "test@example.com", password: "password1234", password_confirmation: "password1234")
    assert user.update(timezone: "America/New_York")
  end

  test "can add password later" do
    user = User.create!(email: "test@example.com")
    assert_not user.has_password?

    assert user.update(password: "newpassword123", password_confirmation: "newpassword123")
    assert user.has_password?
  end
end
