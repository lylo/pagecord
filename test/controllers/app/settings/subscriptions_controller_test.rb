require "test_helper"
require "minitest/autorun"

class App::Settings::SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

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

  test "should cancel subscription" do
    paddle_api_mock = Minitest::Mock.new
    paddle_api_mock.expect :cancel_subscription, true, [ @user.subscription.paddle_subscription_id ]

    PaddleApi.stub :new, paddle_api_mock do
      delete app_settings_subscription_url(@user.subscription)
    end

    assert_redirected_to app_settings_path
    assert @user.subscription.reload.cancelled?
  end

  test "should get cancel_confirm" do
    get cancel_confirm_app_settings_subscriptions_path
    assert_response :success
  end
end
