require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should show log in page" do
    get login_url
    assert_response :success
  end

  test "should send verification email for valid credentials" do
    user = users(:joel)

    assert_emails 1 do
      post sessions_url, params: { user: { username: user.username, email: user.email } }
    end

    assert_redirected_to thanks_sessions_path
  end

  test "should not send verification email for invalid credentials" do
    assert_emails 0 do
      post sessions_url, params: { user: { username: "nope", email: "nope@nope.com" } }
    end

    assert_redirected_to thanks_sessions_path
  end

  test "should destroy session" do
    delete logout_url
    assert_redirected_to root_path
  end
end