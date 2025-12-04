require "test_helper"

class SessionsPasswordControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:joel)
    @user.update!(password: "testpass1234", password_confirmation: "testpass1234")
  end

  test "login with correct password" do
    post sessions_url, params: {
      user: { subdomain: @user.blog.subdomain, password: "testpass1234" }
    }

    assert_redirected_to app_root_path
    assert_equal @user.id, session[:user_id]
  end

  test "login with wrong password" do
    post sessions_url, params: {
      user: { subdomain: @user.blog.subdomain, password: "wrongpassword" }
    }

    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end

  test "email login still works" do
    assert_emails 1 do
      post sessions_url, params: {
        user: { subdomain: @user.blog.subdomain, email: @user.email }
      }
    end

    assert_redirected_to thanks_sessions_path
  end
end
