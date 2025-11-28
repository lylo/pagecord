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

  test "delete account as free user schedules destroy and cancellation email jobs" do
    free_user = users(:vivian)
    login_as free_user

    assert_enqueued_with(job: DestroyUserJob, args: [ free_user.id ]) do
      assert_enqueued_with(job: SendCancellationEmailJob, args: [ free_user.id, { subscriber: false } ]) do
        delete app_settings_user_url(free_user)
      end
    end

    assert_redirected_to root_url
  end
end
