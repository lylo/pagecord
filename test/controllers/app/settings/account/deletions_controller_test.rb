require "test_helper"

class App::Settings::Account::DeletionsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:joel)
    login_as @user
  end

  test "should get the deletion confirmation" do
    get new_app_settings_account_deletion_path
    assert_response :success
  end

  test "deleting the account records why and schedules destroy and cancellation email jobs" do
    assert_enqueued_with(job: DestroyUserJob, args: [ @user.id ]) do
      assert_enqueued_with(job: SendCancellationEmailJob, args: [ @user.id, { subscriber: false } ]) do
        post app_settings_account_deletion_url, params: { cancellation: { reason: "moving_platform", feedback: "Found somewhere else" } }
      end
    end

    assert_redirected_to root_url
    cancellation = Cancellation.last
    assert cancellation.account?
    assert cancellation.moving_platform?
    assert_equal "Found somewhere else", cancellation.feedback
    assert_equal @user, cancellation.user
  end

  test "deleting the account without a reason keeps it" do
    assert_no_enqueued_jobs(only: DestroyUserJob) do
      assert_no_difference "Cancellation.count" do
        post app_settings_account_deletion_url, params: { cancellation: { feedback: "" } }
      end
    end

    assert_response :unprocessable_entity
  end

  test "feedback longer than 2000 characters is refused" do
    assert_no_enqueued_jobs(only: DestroyUserJob) do
      post app_settings_account_deletion_url, params: { cancellation: { reason: "something_else", feedback: "a" * 2001 } }
    end

    assert_response :unprocessable_entity
  end

  test "deleting the account signs them out" do
    post app_settings_account_deletion_url, params: { cancellation: { reason: "something_else" } }
    get app_posts_url

    assert_redirected_to login_url
  end
end
