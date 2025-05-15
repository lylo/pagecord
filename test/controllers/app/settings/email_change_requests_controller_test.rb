require "test_helper"

class App::Settings::EmailChangeRequestsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
  end

  test "should create new email change request" do
    assert_difference("EmailChangeRequest.count") do
      post app_settings_email_change_requests_path, params: {
        email_change_request: { new_email: "new_email@example.com" }
      }
    end

    assert_redirected_to app_settings_account_edit_path
    assert_not_nil @user.pending_email_change_request
    assert_equal "new_email@example.com", @user.pending_email_change_request.new_email
  end

  test "should not create email change request with invalid email" do
    assert_no_difference("EmailChangeRequest.count") do
      post app_settings_email_change_requests_path, params: {
        email_change_request: { new_email: "invalid-email" }
      }
    end

    assert_redirected_to app_settings_account_edit_path
  end

  test "should resend verification email" do
    request = @user.email_change_requests.create!(new_email: "new_email@example.com")

    assert_emails 1 do
      post resend_app_settings_email_change_request_path(request)
    end

    assert_redirected_to app_settings_account_edit_path
  end

  test "should destroy email change request" do
    request = @user.email_change_requests.create!(new_email: "new_email@example.com")
    assert_difference("EmailChangeRequest.count", -1) do
      delete app_settings_email_change_request_path(request)
    end
  end

  test "should verify email change request and update user email" do
    request = @user.email_change_requests.create!(new_email: "new_email@example.com")

    get verify_app_settings_email_change_requests_path(request.token_digest)

    assert_redirected_to app_settings_account_edit_path
    assert_equal request.new_email, @user.reload.email
    assert_not_nil request.reload.accepted_at
  end

  test "should not verify expired email change request" do
    request = @user.email_change_requests.create!(
      new_email: "new_email@example.com",
      accepted_at: 1.month.ago,
      created_at: 1.month.ago
    )
    original_email = @user.email

    get verify_app_settings_email_change_requests_path(request.token_digest)

    assert_redirected_to root_path
    @user.reload
    assert_equal original_email, @user.email
  end

  test "should not verify already accepted email change request" do
    request = @user.email_change_requests.create!(
      new_email: "new_email@example.com",
      accepted_at: Time.current
    )
    original_email = @user.email

    get verify_app_settings_email_change_requests_path(request.token_digest)

    assert_redirected_to root_path
    assert_equal original_email, @user.reload.email
  end
end
