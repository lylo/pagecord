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

  test "should log the cancellation with the price they were paying" do
    mock_api = mock
    mock_api.stubs(:cancel_subscription).returns(true)
    PaddleApi.stubs(:new).returns(mock_api)

    io = StringIO.new
    previous = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(io)
    post app_settings_subscriptions_cancellation_url
    Rails.logger = previous

    line = io.string[/\[billing\].*/]
    assert_includes line, "event=cancel_requested"
    assert_includes line, "blog=#{@user.blog.subdomain}"
    assert_includes line, "amount=#{@user.subscription.unit_price}"
    assert_includes line, "source=app"
    assert @user.subscription.reload.cancelled?
  end
end
