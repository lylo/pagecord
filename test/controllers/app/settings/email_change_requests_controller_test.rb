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

    assert_redirected_to edit_app_settings_account_path
    assert_not_nil @user.pending_email_change_request
    assert_equal "new_email@example.com", @user.pending_email_change_request.new_email
  end

  test "should not create email change request with invalid email" do
    assert_no_difference("EmailChangeRequest.count") do
      post app_settings_email_change_requests_path, params: {
        email_change_request: { new_email: "invalid-email" }
      }
    end

    assert_redirected_to edit_app_settings_account_path
  end

  test "should destroy email change request" do
    request = @user.email_change_requests.create!(new_email: "new_email@example.com")
    assert_difference("EmailChangeRequest.count", -1) do
      delete app_settings_email_change_request_path(request)
    end
  end
end
