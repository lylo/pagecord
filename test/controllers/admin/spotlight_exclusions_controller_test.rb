require "test_helper"

class Admin::SpotlightExclusionsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    login_as users(:joel)
    @user = users(:elliot)
  end

  test "create excludes the blog from spotlight" do
    assert @user.blog.spotlit?

    post admin_user_spotlight_exclusion_url(@user)

    assert_redirected_to admin_user_path(@user)
    assert_not @user.blog.reload.spotlit?
  end

  test "destroy includes the blog back in spotlight" do
    @user.blog.exclude_from_spotlight

    delete admin_user_spotlight_exclusion_url(@user)

    assert_redirected_to admin_user_path(@user)
    assert @user.blog.reload.spotlit?
  end
end
