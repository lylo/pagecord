require "test_helper"

class App::Settings::UsersControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    login_as @user
  end

  test "delete account" do
    assert_performed_jobs 1 do
      assert_difference("User.kept.count", -1) do
        delete app_settings_user_url(@user)
      end
    end

    assert_redirected_to root_url
    assert_not User.kept.exists?(@user.id)
    assert User.exists?(@user.id) # soft delete
  end
end
