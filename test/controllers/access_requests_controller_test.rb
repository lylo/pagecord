require "test_helper"

class AccessRequestsControllerTest < ActionDispatch::IntegrationTest
  test "should verify open access request" do
    user = users(:elliot)

    get verify_access_request_url(access_requests(:elliot).token_digest)

    assert_redirected_to app_posts_url
    assert user.reload.verified
  end

  test "should send welcome email when verifying access request" do
    user = users(:elliot)

    assert_emails 1 do
      get verify_access_request_url(access_requests(:elliot).token_digest)
    end

    assert_redirected_to app_posts_url
    assert user.reload.verified
  end

  test "should not verify expired access request" do
    user = users(:elliot)

    get verify_access_request_url(access_requests(:elliot_expired).token_digest)

    assert_redirected_to root_path
    assert_not user.reload.verified
  end

  test "should not verify access request with invalid token" do
    get verify_access_request_url("invalid")

    assert_redirected_to root_path
  end

  test "should re-verify access request with 5 minutes" do
    user = users(:joel)
    access_request = user.access_requests.create!(accepted_at: 1.minute.ago)
    get verify_access_request_url(access_request.token_digest)

    assert_redirected_to app_posts_path
  end

  test "should not re-verify access request after 5 minutes" do
    user = users(:joel)
    access_request = user.access_requests.create!(accepted_at: 6.minutes.ago)
    get verify_access_request_url(access_request.token_digest)

    assert_redirected_to root_path
  end

  test "should reject password_reset token for login" do
    user = users(:joel)
    access_request = user.access_requests.create!(purpose: "password_reset")

    get verify_access_request_url(access_request.token_digest)

    assert_redirected_to root_path
  end
end
