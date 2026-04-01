require "test_helper"

class Admin::SuppressionsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @admin_user = users(:joel)
    login_as @admin_user
  end

  test "should require admin access" do
    login_as users(:vivian)
    get admin_suppressions_url
    assert_redirected_to root_path
  end

  test "index shows suppressions from postmark" do
    Postmark::ApiClient.any_instance.stubs(:dump_suppressions).returns([
      { email_address: "fred@example.com", suppression_reason: "HardBounce", created_at: 1.day.ago }
    ])

    get admin_suppressions_url
    assert_response :success
    assert_select "td", text: /fred@example.com/
    assert_select "td", text: /joel/ # subscriber's blog
  end

  test "index shows not in DB for suppressions with no matching subscriber" do
    Postmark::ApiClient.any_instance.stubs(:dump_suppressions).returns([
      { email_address: "nobody@example.com", suppression_reason: "HardBounce", created_at: 1.day.ago }
    ])

    get admin_suppressions_url
    assert_response :success
    assert_select "span", text: /not in DB/
  end

  test "index shows error message on invalid API key" do
    Postmark::ApiClient.any_instance.stubs(:dump_suppressions).raises(Postmark::InvalidApiKeyError)

    get admin_suppressions_url
    assert_response :success
    assert_select "div", text: /Postmark API token is missing or invalid/
  end

  test "destroy deletes subscribers matching the given email" do
    assert_difference "EmailSubscriber.count", -1 do
      delete admin_suppressions_url, params: { email: "fred@example.com" }
    end

    assert_redirected_to admin_suppressions_path
    assert_equal "Subscriber deleted.", flash[:notice]
  end

  test "destroy_all deletes all subscribers matching postmark suppressions" do
    Postmark::ApiClient.any_instance.stubs(:dump_suppressions).returns([
      { email_address: "fred@example.com", suppression_reason: "HardBounce", created_at: 1.day.ago }
    ])

    assert_difference "EmailSubscriber.count", -1 do
      delete destroy_all_admin_suppressions_url
    end

    assert_redirected_to admin_suppressions_path
    assert_match /Deleted 1 suppressed subscriber/, flash[:notice]
  end

  test "destroy_all with no matching subscribers redirects with zero count" do
    Postmark::ApiClient.any_instance.stubs(:dump_suppressions).returns([
      { email_address: "nobody@example.com", suppression_reason: "HardBounce", created_at: 1.day.ago }
    ])

    assert_no_difference "EmailSubscriber.count" do
      delete destroy_all_admin_suppressions_url
    end

    assert_redirected_to admin_suppressions_path
    assert_match /Deleted 0 suppressed subscribers/, flash[:notice]
  end
end
