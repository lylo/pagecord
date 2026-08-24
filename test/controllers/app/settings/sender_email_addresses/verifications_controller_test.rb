require "test_helper"

class App::Settings::SenderEmailAddresses::VerificationsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    login_as @user
  end

  test "should verify sender email address with valid token" do
    sender = @blog.sender_email_addresses.create!(email: "sender@example.com")

    get app_settings_sender_email_addresses_verification_path(token: sender.token_digest)

    assert_redirected_to edit_app_settings_account_path
    assert_match "Sender email address has been verified", flash[:notice]

    sender.reload
    assert sender.accepted?
  end

  test "should not verify sender email address with invalid token" do
    get app_settings_sender_email_addresses_verification_path(token: "invalid_token")

    assert_redirected_to edit_app_settings_account_path
    assert_match "Invalid or expired verification link", flash[:alert]
  end

  test "should not verify already verified sender email address" do
    @blog.sender_email_addresses.create!(
      email: "sender@example.com",
      accepted_at: Time.current
      )

    get app_settings_sender_email_addresses_verification_path(token: "any_token")

    assert_redirected_to edit_app_settings_account_path
    assert_match "Invalid or expired verification link", flash[:alert]
  end

  test "should verify sender email address when logged out" do
    sender = @blog.sender_email_addresses.create!(email: "sender@example.com")

    # Sign out user
    delete logout_path

    get app_settings_sender_email_addresses_verification_path(token: sender.token_digest)

    assert_redirected_to login_path
    assert_match "Sender email address has been verified", flash[:notice]

    sender.reload
    assert sender.accepted?
  end

  test "should verify sender email address when logged in" do
    sender = @blog.sender_email_addresses.create!(email: "sender@example.com")

    # User is already logged in from setup
    get app_settings_sender_email_addresses_verification_path(token: sender.token_digest)

    assert_redirected_to edit_app_settings_account_path
    assert_match "Sender email address has been verified", flash[:notice]

    sender.reload
    assert sender.accepted?
  end

  test "should redirect to login for invalid token when logged out" do
    # Sign out user
    delete logout_path

    get app_settings_sender_email_addresses_verification_path(token: "invalid_token")

    assert_redirected_to login_path
    assert_match "Invalid or expired verification link", flash[:alert]
  end
end
