require "test_helper"

class App::Settings::EmailChangeRequests::VerificationsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
  end

  test "should verify email change request and update user email" do
    request = @user.email_change_requests.create!(new_email: "new_email@example.com")

    get app_settings_email_change_requests_verification_path(request.token_digest)

    assert_redirected_to edit_app_settings_account_path
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

    get app_settings_email_change_requests_verification_path(request.token_digest)

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

    get app_settings_email_change_requests_verification_path(request.token_digest)

    assert_redirected_to root_path
    assert_equal original_email, @user.reload.email
  end
end
