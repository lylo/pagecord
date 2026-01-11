require "test_helper"
require "mocha/minitest"

class App::Settings::SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:joel)
    login_as @user
  end

  test "should get index" do
    get app_settings_subscriptions_path
    assert_response :success
  end

  test "should get thanks" do
    get thanks_app_settings_subscriptions_path
    assert_response :success
  end

  test "should cancel subscription and schedule cancellation email" do
    mock_api = mock
    mock_api.expects(:cancel_subscription).with(@user.subscription.paddle_subscription_id).returns(true)
    PaddleApi.stubs(:new).returns(mock_api)

    assert_enqueued_with(job: SendCancellationEmailJob, args: [ @user.id, { subscriber: true } ]) do
      delete app_settings_subscription_url(@user.subscription)
    end

    assert_redirected_to app_settings_path
    assert @user.subscription.reload.cancelled?
  end

  test "should get cancel_confirm" do
    get cancel_confirm_app_settings_subscriptions_path
    assert_response :success
  end

  test "should display stored unit_price on settings page" do
    get app_settings_subscriptions_path
    assert_response :success
    assert_select "body", text: /\$20/
  end
end
