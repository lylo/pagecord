require "application_system_test_case"

class SignUpTest < ApplicationSystemTestCase
  test "sign up and verify email" do
    visit new_signup_path

    fill_in "user[blogs_attributes][0][title]", with: "Test User"
    assert_field "user[blogs_attributes][0][subdomain]", with: "testuser"
    fill_in "user[email]", with: "test@example.com"

    # Backdate the signed form timestamp instead of waiting out the anti-bot
    # minimum in real time.
    execute_script("document.querySelector('input[name=rendered_at]').value = #{signed_rendered_at.to_json}")
    click_on "Send my letter"

    assert_current_path signups_thanks_path, ignore_query: true
    assert_equal "Test User", User.kept.find_by!(email: "test@example.com").blog.title
  end
end
