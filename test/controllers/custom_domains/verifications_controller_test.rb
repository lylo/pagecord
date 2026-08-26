require "test_helper"

class CustomDomains::VerificationsControllerTest < ActionDispatch::IntegrationTest
  test "should return ok for valid custom domain with active subscription" do
    get custom_domain_verification_path, params: { domain: "annie.blog" }
    assert_response :ok
  end

  test "should return not found for nonexistent custom domain" do
    get custom_domain_verification_path, params: { domain: "nonexistent.com" }
    assert_response :unprocessable_content
  end

  test "should return bad request when domain parameter is missing" do
    get custom_domain_verification_path
    assert_response :bad_request
  end

  test "should return bad request when domain parameter is blank" do
    get custom_domain_verification_path, params: { domain: "" }
    assert_response :bad_request
  end

  test "should return ok for custom domain within the lapsed grace period" do
    user = users(:annie)
    user.subscription.update(next_billed_at: 1.day.ago)
    assert user.subscription.lapsed?

    get custom_domain_verification_path, params: { domain: "annie.blog" }
    assert_response :ok
  end

  test "should return not found for custom domain beyond the lapsed grace period" do
    users(:annie).subscription.update(next_billed_at: (Subscribable::CUSTOM_DOMAIN_GRACE_PERIOD + 1).days.ago)

    get custom_domain_verification_path, params: { domain: "annie.blog" }
    assert_response :unprocessable_content
  end
end
