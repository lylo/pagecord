require "test_helper"
require "mocha/minitest"

class App::Settings::Subscriptions::CancellationsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:joel)
    login_as @user
  end

  test "should get the cancellation confirmation" do
    get new_app_settings_subscriptions_cancellation_path
    assert_response :success
  end

  test "should cancel subscription and schedule cancellation email" do
    mock_api = mock
    mock_api.expects(:cancel_subscription).with(@user.subscription.paddle_subscription_id).returns(true)
    PaddleApi.stubs(:new).returns(mock_api)

    assert_enqueued_with(job: SendCancellationEmailJob, args: [ @user.id, { subscriber: true } ]) do
      post app_settings_subscriptions_cancellation_url
    end

    assert_redirected_to app_settings_path
    assert_equal "Your subscription has been cancelled. You'll keep access until the end of your current billing period.", flash[:notice]
    assert @user.subscription.reload.cancelled?
  end
end
