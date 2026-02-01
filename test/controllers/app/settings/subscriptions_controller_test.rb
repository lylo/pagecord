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

  test "should change plan from annual to monthly" do
    mock_response = mock
    mock_response.stubs(:success?).returns(true)
    mock_api = mock
    mock_api.expects(:update_subscription_items)
      .with(@user.subscription.paddle_subscription_id, SubscriptionsHelper.price_id(:monthly))
      .returns(mock_response)
    PaddleApi.stubs(:new).returns(mock_api)

    post change_plan_app_settings_subscriptions_path(plan: "monthly")

    assert_redirected_to app_settings_path
    assert_equal "Your plan has been updated to monthly!", flash[:notice]
  end

  test "should change plan from monthly to annual" do
    @user.subscription.update!(plan: :monthly)
    mock_response = mock
    mock_response.stubs(:success?).returns(true)
    mock_api = mock
    mock_api.expects(:update_subscription_items)
      .with(@user.subscription.paddle_subscription_id, SubscriptionsHelper.price_id(:annual))
      .returns(mock_response)
    PaddleApi.stubs(:new).returns(mock_api)

    post change_plan_app_settings_subscriptions_path(plan: "annual")

    assert_redirected_to app_settings_path
    assert_equal "Your plan has been updated to annual!", flash[:notice]
  end

  test "should reject invalid plan" do
    post change_plan_app_settings_subscriptions_path(plan: "invalid")

    assert_redirected_to app_settings_subscriptions_path
    assert_equal "Invalid plan", flash[:alert]
  end

  test "should handle failed plan change" do
    mock_response = mock
    mock_response.stubs(:success?).returns(false)
    mock_api = mock
    mock_api.expects(:update_subscription_items).returns(mock_response)
    PaddleApi.stubs(:new).returns(mock_api)

    post change_plan_app_settings_subscriptions_path(plan: "monthly")

    assert_redirected_to app_settings_subscriptions_path
    assert_equal "Unable to change plan. Please try again.", flash[:alert]
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

    post resume_app_settings_subscriptions_path

    assert_redirected_to app_settings_path
    assert_equal "Your subscription has been resumed!", flash[:notice]
    assert_nil @user.subscription.reload.cancelled_at
  end

  test "should not resume non-cancelled subscription" do
    post resume_app_settings_subscriptions_path

    assert_redirected_to app_settings_subscriptions_path
  end

  test "should handle failed resume" do
    @user.subscription.update!(cancelled_at: Time.current)
    mock_response = mock
    mock_response.stubs(:success?).returns(false)
    mock_api = mock
    mock_api.expects(:resume_subscription).returns(mock_response)
    PaddleApi.stubs(:new).returns(mock_api)

    post resume_app_settings_subscriptions_path

    assert_redirected_to app_settings_subscriptions_path
    assert_equal "Unable to resume subscription. Please try again.", flash[:alert]
    assert @user.subscription.reload.cancelled?
  end
end
