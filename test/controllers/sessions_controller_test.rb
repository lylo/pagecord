require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  test "should show log in page" do
    get login_url
    assert_response :success
  end

  test "should send verification email for valid credentials" do
    user = users(:joel)

    assert_emails 1 do
      post sessions_url, params: { user: { subdomain: user.blog.subdomain, email: user.email } }
    end

    assert_redirected_to thanks_sessions_path
  end

  test "should send verification email for valid credentials with whitespace" do
    user = users(:joel)

    assert_emails 1 do
      post sessions_url, params: { user: { subdomain: "#{user.blog.subdomain} ", email: "#{user.email} " } }
    end

    assert_redirected_to thanks_sessions_path
  end

  test "should send verification email for valid credentials regardless of case" do
    user = users(:joel)

    assert_emails 1 do
      post sessions_url, params: { user: { subdomain: user.blog.subdomain.upcase, email: user.email.upcase } }
    end

    assert_redirected_to thanks_sessions_path
  end

  test "should not send verification email for invalid credentials" do
    assert_emails 0 do
      post sessions_url, params: { user: { subdomain: "nope", email: "nope@nope.com" } }
    end

    assert_redirected_to thanks_sessions_path
  end

  test "should destroy session" do
    delete logout_url
    assert_redirected_to root_path
  end

  test "should redirect to app root if already logged in" do
    login_as users(:joel)

    get login_url
    assert_redirected_to app_root_path
  end

  test "login with correct password" do
    user = users(:joel)
    user.update!(password: "testpass1234", password_confirmation: "testpass1234")

    post sessions_url, params: {
      user: { subdomain: user.blog.subdomain, password: "testpass1234" }
    }

    assert_redirected_to app_root_path
    assert_equal user.id, session[:user_id]
  end

  test "login with wrong password" do
    user = users(:joel)
    user.update!(password: "testpass1234", password_confirmation: "testpass1234")

    post sessions_url, params: {
      user: { subdomain: user.blog.subdomain, password: "wrongpassword" }
    }

    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end
end
