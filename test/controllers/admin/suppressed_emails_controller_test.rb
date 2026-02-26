require "test_helper"

class Admin::SuppressedEmailsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @admin_user = users(:joel)
    login_as @admin_user
  end

  test "should get index" do
    get admin_suppressed_emails_url
    assert_response :success
    assert_select "table"
  end

  test "should filter by bounce reason" do
    get admin_suppressed_emails_url(reason: "bounce")
    assert_response :success
    assert_includes @response.body, "bounced@example.com"
    assert_not_includes @response.body, "complained@example.com"
  end

  test "should filter by complaint reason" do
    get admin_suppressed_emails_url(reason: "complaint")
    assert_response :success
    assert_includes @response.body, "complained@example.com"
    assert_not_includes @response.body, "bounced@example.com"
  end

  test "should destroy suppression" do
    suppression = email_suppressions(:bounced)

    assert_difference "Email::Suppression.count", -1 do
      delete admin_suppressed_email_url(suppression)
    end

    assert_redirected_to admin_suppressed_emails_path
  end

  test "should require admin access" do
    non_admin = users(:vivian)
    login_as non_admin

    get admin_suppressed_emails_url
    assert_redirected_to root_path
  end
end
