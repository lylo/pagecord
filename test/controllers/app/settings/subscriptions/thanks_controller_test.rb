require "test_helper"
require "mocha/minitest"

class App::Settings::Subscriptions::ThanksControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:joel)
    login_as @user
  end

  test "should get thanks" do
    get app_settings_subscriptions_thanks_path
    assert_response :success
  end
end
