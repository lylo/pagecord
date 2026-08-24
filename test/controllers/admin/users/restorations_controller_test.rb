require "test_helper"

class Admin::Users::RestorationsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    login_as users(:joel)
  end

  test "should restore user" do
    user = users(:vivian)
    user.discard!

    assert_difference("User.kept.count", 1) do
      post admin_user_restoration_path(user)
    end

    assert_redirected_to admin_users_path
    assert_equal "User was successfully restored", flash[:notice]
    assert_not user.reload.discarded?
  end

  test "should touch all blogs when restoring user" do
    user = users(:annie)
    second_blog = user.blogs.create!(subdomain: "anniecache")
    old_time = 2.days.ago
    user.blogs.update_all(updated_at: old_time)
    user.discard!

    post admin_user_restoration_path(user)

    assert_redirected_to admin_users_path
    assert_operator user.blog.reload.updated_at, :>, old_time
    assert_operator second_blog.reload.updated_at, :>, old_time
  end
end
