require "test_helper"
require "mocha/minitest"

class App::Settings::Subscriptions::CancellationsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:joel)
    login_as @user
    @params = { cancellation: { reason: "too_expensive", feedback: "Money is tight" } }
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
      post app_settings_subscriptions_cancellation_url, params: @params
    end

    assert_redirected_to app_settings_path
    assert_equal "Your subscription has been cancelled. You'll keep access until the end of your current billing period.", flash[:notice]
    assert @user.subscription.reload.cancelled?
    assert Cancellation.last.subscription?
    assert Cancellation.last.too_expensive?
    assert_equal "Money is tight", Cancellation.last.feedback
  end

  test "cancelling without a reason keeps the subscription" do
    PaddleApi.any_instance.expects(:cancel_subscription).never

    assert_no_difference "Cancellation.count" do
      post app_settings_subscriptions_cancellation_url, params: { cancellation: { feedback: "" } }
    end

    assert_response :unprocessable_entity
    assert_not @user.subscription.reload.cancelled?
  end

  test "should log the cancellation with the price they were paying" do
    mock_api = mock
    mock_api.stubs(:cancel_subscription).returns(true)
    PaddleApi.stubs(:new).returns(mock_api)

    io = StringIO.new
    previous = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(io)
    post app_settings_subscriptions_cancellation_url, params: @params
    Rails.logger = previous

    line = io.string[/\[billing\].*/]
    assert_includes line, "event=cancel_requested"
    assert_includes line, "blog=#{@user.blog.subdomain}"
    assert_includes line, "amount=#{@user.subscription.unit_price}"
    assert_includes line, "source=app"
    assert_includes line, "cancel_reason=too_expensive"
    assert @user.subscription.reload.cancelled?
  end

  test "a cancellation Paddle refuses sends them back to try again" do
    PaddleApi.any_instance.stubs(:cancel_subscription).raises(PaddleApi::Error, "boom")

    assert_no_enqueued_jobs(only: SendCancellationEmailJob) do
      post app_settings_subscriptions_cancellation_url, params: @params
    end

    assert_redirected_to new_app_settings_subscriptions_cancellation_path
    assert_match "couldn't cancel", flash[:error]
    assert_not @user.subscription.reload.cancelled?
  end
end
