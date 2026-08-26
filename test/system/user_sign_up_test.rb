require "application_system_test_case"

class SignUpTest < ApplicationSystemTestCase
  test "sign up and verify email" do
    visit new_signup_path

    fill_in "user[blogs_attributes][0][subdomain]", with: "testuser"
    fill_in "user[email]", with: "test@example.com"

    # Backdate the signed form timestamp instead of waiting out the anti-bot
    # minimum in real time.
    execute_script("document.querySelector('input[name=rendered_at]').value = #{signed_rendered_at.to_json}")
    click_on "Create account"

    assert_current_path signups_thanks_path, ignore_query: true
    assert User.kept.exists?(email: "test@example.com"), "User should be created"
  end
end
