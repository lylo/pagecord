require "test_helper"

class AccessRequestsControllerTest < ActionDispatch::IntegrationTest
  test "should verify open access request" do
    user = users(:elliot)

    get verify_access_request_url(access_requests(:elliot).token_digest)

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

  test "should not re-verify accepted access request" do
    get verify_access_request_url(access_requests(:joel).token_digest)

    assert_redirected_to root_path
  end
end