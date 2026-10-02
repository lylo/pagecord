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

  test "should display stored unit_price on settings page" do
    get app_settings_subscriptions_path
    assert_response :success
    assert_select "body", text: /\$20/
  end

  test "should tell a past due subscriber their payment failed instead of offering renewals and upgrades" do
    @user.subscription.update!(paddle_status: "past_due")

    get app_settings_subscriptions_path

    assert_response :success
    assert_select "body", text: /Your last payment didn't go through/
    assert_select "body", text: /Renews/, count: 0
    assert_select "body", text: /Upgrade to Supporter/, count: 0
  end
end
