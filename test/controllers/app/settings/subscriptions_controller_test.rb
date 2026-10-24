require "test_helper"
require "mocha/minitest"

class App::Settings::SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:joel)
    login_as @user
  end

  test "should display stored unit_price on settings page" do
    get app_settings_subscriptions_path
    assert_response :success
    assert_select "body", text: /\$20/
  end

  test "a cancelled subscriber can resume and is not offered a second subscription" do
    @user.subscription.update!(cancelled_at: Time.current)

    get app_settings_subscriptions_path

    assert_response :success
    assert_select "body", text: /scheduled for cancellation/
    assert_select "body", text: /Resume Subscription/
    assert_select "body", text: /Subscribe Monthly/, count: 0
  end

  test "a complimentary subscriber sees no billing controls" do
    @user.subscription.update!(plan: "complimentary")

    get app_settings_subscriptions_path

    assert_response :success
    assert_select "body", text: /free Pagecord Premium subscription/
    assert_select "body", text: /Subscribe Monthly/, count: 0
    assert_select "body", text: /Cancel subscription/, count: 0
  end

  test "a free user is offered a subscription" do
    free_user = users(:vivian)
    free_user.update!(trial_ends_at: nil)
    login_as free_user

    get app_settings_subscriptions_path

    assert_response :success
    assert_select "body", text: /free plan/
    assert_select "body", text: /Subscribe Monthly/
  end

  test "a trial user is offered a subscription" do
    trial_user = users(:vivian)
    trial_user.update!(trial_ends_at: 3.days.from_now)
    login_as trial_user

    get app_settings_subscriptions_path

    assert_response :success
    assert_select "body", text: /free trial/
    assert_select "body", text: /Subscribe Monthly/
  end

  test "a lapsed subscriber is told so and offered a restart" do
    @user.subscription.update!(paddle_status: "canceled", next_billed_at: 1.day.ago)

    get app_settings_subscriptions_path

    assert_response :success
    assert_select "body", text: /subscription lapsed on/
    assert_select "body", text: /Restart Monthly/
    assert_select "body", text: /free plan/, count: 0
  end

  test "a failed renewal asks for new card details rather than offering a second subscription" do
    @user.subscription.update!(paddle_status: "past_due", next_billed_at: 1.hour.ago)

    get app_settings_subscriptions_path

    assert_response :success
    assert_select "body", text: /Your last payment didn't go through/
    assert_select "body", text: /Subscribe Monthly/, count: 0
    assert_select "body", text: /Renews/, count: 0
    assert_select "body", text: /Upgrade to Supporter/, count: 0
  end
end
