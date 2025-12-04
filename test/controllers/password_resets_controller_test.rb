require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joel)
  end

  test "new shows password reset form" do
    get new_password_reset_url
    assert_response :success
  end

  test "create sends reset email and redirects" do
    assert_emails 1 do
      post password_resets_url, params: {
        user: { subdomain: @user.blog.subdomain, email: @user.email }
      }
    end

    assert_redirected_to thanks_password_resets_path
  end

  test "create does not reveal if user exists" do
    assert_emails 0 do
      post password_resets_url, params: {
        user: { subdomain: "nonexistent", email: "nobody@example.com" }
      }
    end

    assert_redirected_to thanks_password_resets_path
  end

  test "edit shows password form with valid token" do
    access_request = @user.access_requests.create!(purpose: "password_reset")

    get edit_password_reset_url(access_request.token_digest)
    assert_response :success
  end

  test "edit rejects invalid token" do
    get edit_password_reset_url("invalid-token")
    assert_redirected_to login_path
  end

  test "edit rejects login token" do
    access_request = @user.access_requests.create!(purpose: "login")

    get edit_password_reset_url(access_request.token_digest)
    assert_redirected_to login_path
  end

  test "update sets password and signs in" do
    access_request = @user.access_requests.create!(purpose: "password_reset")

    patch password_reset_url(access_request.token_digest), params: {
      user: { password: "newpass123456", password_confirmation: "newpass123456" }
    }

    assert_redirected_to app_root_path
    assert @user.reload.authenticate("newpass123456")
  end

  test "update rejects expired token" do
    access_request = @user.access_requests.create!(purpose: "password_reset")
    access_request.update!(expires_at: 2.days.ago)

    patch password_reset_url(access_request.token_digest), params: {
      user: { password: "newpass123456", password_confirmation: "newpass123456" }
    }

    assert_redirected_to login_path
  end
end
