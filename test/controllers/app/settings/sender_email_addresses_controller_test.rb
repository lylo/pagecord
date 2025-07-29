require "test_helper"

class App::Settings::SenderEmailAddressesControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @blog = @user.blog
    login_as @user
  end

  test "should create new sender email address" do
    assert_difference("SenderEmailAddress.count") do
      post app_settings_sender_email_addresses_path, params: {
        sender_email_address: { email: "sender@example.com" }
      }
    end

    assert_redirected_to app_settings_account_edit_path
    assert_match "Verification email has been sent to sender@example.com", flash[:notice]

    sender = @blog.sender_email_addresses.last
    assert_equal "sender@example.com", sender.email
    assert_not sender.accepted?
  end

  test "should send verification email on create" do
    assert_emails 1 do
      post app_settings_sender_email_addresses_path, params: {
        sender_email_address: { email: "sender@example.com" }
      }
    end
  end

  test "should not create sender email address with invalid email" do
    assert_no_difference("SenderEmailAddress.count") do
      post app_settings_sender_email_addresses_path, params: {
        sender_email_address: { email: "invalid-email" }
      }
    end

    assert_redirected_to app_settings_account_edit_path
    assert_match "is invalid", flash[:alert]
  end

  test "should not create duplicate sender email address for same blog" do
    @blog.sender_email_addresses.create!(email: "sender@example.com")

    assert_no_difference("SenderEmailAddress.count") do
      post app_settings_sender_email_addresses_path, params: {
        sender_email_address: { email: "sender@example.com" }
      }
    end

    assert_redirected_to app_settings_account_edit_path
    assert_match "has already been taken", flash[:alert]
  end


  test "should destroy sender email address" do
    sender = @blog.sender_email_addresses.create!(email: "sender@example.com")

    assert_difference("SenderEmailAddress.count", -1) do
      delete app_settings_sender_email_address_path(sender)
    end

    assert_redirected_to app_settings_account_edit_path
    assert_match "Sender email address has been removed", flash[:notice]
  end

  test "should verify sender email address with valid token" do
    sender = @blog.sender_email_addresses.create!(email: "sender@example.com")

    get verify_app_settings_sender_email_addresses_path(token: sender.token_digest)

    assert_redirected_to app_settings_account_edit_path
    assert_match "Sender email address has been verified", flash[:notice]

    sender.reload
    assert sender.accepted?
  end

  test "should not verify sender email address with invalid token" do
    get verify_app_settings_sender_email_addresses_path(token: "invalid_token")

    assert_redirected_to app_settings_account_edit_path
    assert_match "Invalid or expired verification link", flash[:alert]
  end

  test "should not verify already verified sender email address" do
    @blog.sender_email_addresses.create!(
      email: "sender@example.com",
      accepted_at: Time.current
      )

    get verify_app_settings_sender_email_addresses_path(token: "any_token")

    assert_redirected_to app_settings_account_edit_path
    assert_match "Invalid or expired verification link", flash[:alert]
  end

  test "should verify sender email address when logged out" do
    sender = @blog.sender_email_addresses.create!(email: "sender@example.com")

    # Sign out user
    delete logout_path

    get verify_app_settings_sender_email_addresses_path(token: sender.token_digest)

    assert_redirected_to login_path
    assert_match "Sender email address has been verified", flash[:notice]

    sender.reload
    assert sender.accepted?
  end

  test "should verify sender email address when logged in" do
    sender = @blog.sender_email_addresses.create!(email: "sender@example.com")

    # User is already logged in from setup
    get verify_app_settings_sender_email_addresses_path(token: sender.token_digest)

    assert_redirected_to app_settings_account_edit_path
    assert_match "Sender email address has been verified", flash[:notice]

    sender.reload
    assert sender.accepted?
  end

  test "should redirect to login for invalid token when logged out" do
    # Sign out user
    delete logout_path

    get verify_app_settings_sender_email_addresses_path(token: "invalid_token")

    assert_redirected_to login_path
    assert_match "Invalid or expired verification link", flash[:alert]
  end
end
