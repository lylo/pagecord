require "test_helper"

class CustomDomainsControllerTest < ActionDispatch::IntegrationTest
  test "should return ok for valid custom domain with active subscription" do
    get verify_custom_domain_path, params: { domain: "annie.blog" }
    assert_response :ok
  end

  test "should return not found for nonexistent custom domain" do
    get verify_custom_domain_path, params: { domain: "nonexistent.com" }
    assert_response :not_found
  end

  test "should return bad request when domain parameter is missing" do
    get verify_custom_domain_path
    assert_response :bad_request
  end

  test "should return bad request when domain parameter is blank" do
    get verify_custom_domain_path, params: { domain: "" }
    assert_response :bad_request
  end

  test "should return not found for custom domain with inactive subscription" do
    user = users(:annie)
    user.subscription.update(next_billed_at: 1.day.ago)
    assert user.subscription.lapsed?

    get verify_custom_domain_path, params: { domain: "annie.blog" }
    assert_response :not_found
  end
end
