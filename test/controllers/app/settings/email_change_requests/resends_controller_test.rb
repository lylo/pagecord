require "test_helper"

class App::Settings::EmailChangeRequests::ResendsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
  end

  test "should resend verification email" do
    request = @user.email_change_requests.create!(new_email: "new_email@example.com")

    assert_emails 1 do
      post app_settings_email_change_request_resend_path(request)
    end

    assert_redirected_to edit_app_settings_account_path
  end
end
