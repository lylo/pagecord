require "test_helper"
require "mocha/minitest"

class App::Settings::Subscriptions::ResumptionsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:joel)
    login_as @user
  end

  test "should resume cancelled subscription" do
    @user.subscription.update!(cancelled_at: Time.current)
    mock_response = mock
    mock_response.stubs(:success?).returns(true)
    mock_api = mock
    mock_api.expects(:resume_subscription)
      .with(@user.subscription.paddle_subscription_id)
      .returns(mock_response)
    PaddleApi.stubs(:new).returns(mock_api)

    post app_settings_subscriptions_resumption_path

    assert_redirected_to app_settings_path
    assert_equal "Your subscription has been resumed!", flash[:notice]
    assert_nil @user.subscription.reload.cancelled_at
  end

  test "should not resume non-cancelled subscription" do
    post app_settings_subscriptions_resumption_path

    assert_redirected_to app_settings_subscriptions_path
  end

  test "should handle failed resume" do
    @user.subscription.update!(cancelled_at: Time.current)
    mock_response = mock
    mock_response.stubs(:success?).returns(false)
    mock_api = mock
    mock_api.expects(:resume_subscription).returns(mock_response)
    PaddleApi.stubs(:new).returns(mock_api)

    post app_settings_subscriptions_resumption_path

    assert_redirected_to app_settings_subscriptions_path
    assert_equal "Unable to resume subscription. Please try again.", flash[:alert]
    assert @user.subscription.reload.cancelled?
  end
end
