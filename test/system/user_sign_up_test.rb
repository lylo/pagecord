require "application_system_test_case"

class SignUpTest < ApplicationSystemTestCase
  test "sign up and verify email" do
    visit new_signup_path

    fill_in "user[username]", with: "testuser"
    fill_in "user[email]", with: "test@example.com"
    click_on "Create account"

    user = User.kept.find_by(email: "test@example.com")
    assert user, "User should be created"
  end

  test "verifying signup email" do
    user = User.create!(username: "testuser", email: "test@example.com")
    user.access_requests.create!

    visit verify_access_request_url(token: user.access_requests.last.token_digest)

    assert_current_path app_posts_path
  end
end
