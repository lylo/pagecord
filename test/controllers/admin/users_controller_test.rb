require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)

    login_as @user
  end

  test "should not discard premium user" do
    user = users(:annie)
    assert user.subscribed?

    delete admin_user_url(user)

    assert_redirected_to admin_stats_path
    assert_equal "You can't discard a premium user", flash[:notice]
    assert_not user.reload.discarded?
  end

  test "should discard regular user" do
    user = users(:vivian)
    assert_difference("User.kept.count", -1) do
      delete admin_user_url(user)
    end

    assert_redirected_to admin_stats_path
    assert_equal "User was successfully discarded", flash[:notice]
    assert user.reload.discarded?
  end
end
