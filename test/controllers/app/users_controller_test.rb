require "test_helper"

class App::UsersControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  test "delete account" do
    user = users(:joel)
    login_as user

    assert_performed_jobs 1 do
      assert_difference("User.count", -1) do
        delete app_user_url(user)
      end
    end

    assert_redirected_to root_url
    refute User.exists?(user.id)
  end
end
