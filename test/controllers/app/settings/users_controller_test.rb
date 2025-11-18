require "test_helper"
require "mocha/minitest"

class App::Settings::UsersControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
  end

  test "delete account" do
    PaddleApi.any_instance.expects(:cancel_subscription)
      .with(@user.subscription.paddle_subscription_id)
      .returns({ "data" => { "id" => "sub_123" } })

    assert_performed_with(job: DestroyUserJob) do
      assert_difference("User.kept.count", -1) do
        delete app_settings_user_url(@user)
      end
    end

    assert_redirected_to root_url
    assert_not User.kept.exists?(@user.id)
    assert User.exists?(@user.id) # soft delete
  end
end
