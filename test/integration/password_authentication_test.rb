require "test_helper"

class PasswordAuthenticationTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  test "signup with password then login" do
    post signups_url, params: {
      user: {
        email: "newuser@example.com",
        password: "password1234",
        password_confirmation: "password1234",
        timezone: "UTC",
        blog_attributes: { subdomain: "newuser" }
      },
      rendered_at: signed_rendered_at
    }

    user = User.find_by(email: "newuser@example.com")
    assert user.has_password?

    post sessions_url, params: {
      user: { subdomain: "newuser", password: "password1234" }
    }

    assert_redirected_to app_root_path
  end

  test "password reset flow" do
    user = users(:joel)
    access_request = user.access_requests.create!(purpose: "password_reset")

    patch password_reset_url(access_request.token_digest), params: {
      user: { password: "newpass123456", password_confirmation: "newpass123456" }
    }

    assert user.reload.authenticate("newpass123456")
    assert_redirected_to app_root_path
  end
end
