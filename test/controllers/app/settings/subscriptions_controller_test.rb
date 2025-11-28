require "test_helper"
require "minitest/autorun"

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
    paddle_api_mock = Minitest::Mock.new
    paddle_api_mock.expect :cancel_subscription, true, [ @user.subscription.paddle_subscription_id ]

    PaddleApi.stub :new, paddle_api_mock do
      assert_enqueued_with(job: SendCancellationEmailJob, args: [ @user.id, { subscriber: true } ]) do
        delete app_settings_subscription_url(@user.subscription)
      end
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
