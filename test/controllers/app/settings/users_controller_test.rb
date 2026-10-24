require "test_helper"
require "mocha/minitest"

class App::Settings::UsersControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:joel)
    login_as @user
  end

  test "delete account as subscriber schedules destroy and cancellation email jobs" do
    assert_enqueued_with(job: DestroyUserJob, args: [ @user.id ]) do
      assert_enqueued_with(job: SendCancellationEmailJob, args: [ @user.id, { subscriber: false } ]) do
        delete app_settings_user_url(@user)
      end
    end

    assert_redirected_to root_url
  end
end
