require "application_system_test_case"

class SignUpTest < ApplicationSystemTestCase
  test "sign up and verify email" do
    visit new_signup_path

    fill_in "user[blogs_attributes][0][subdomain]", with: "testuser"
    fill_in "user[email]", with: "test@example.com"
    sleep 5 # anti-bot protection
    click_on "Create account"

    # Wait for form submission to complete
    sleep 1

    user = User.kept.find_by(email: "test@example.com")
    assert user, "User should be created"
  end

  test "verifying signup email" do
    user = User.create!(email: "test@example.com", blogs_attributes: [ { subdomain: "testuser" } ])
    user.access_requests.create!

    visit verify_access_request_url(token: user.access_requests.last.token_digest)

    assert_current_path app_onboarding_path
  end
end
