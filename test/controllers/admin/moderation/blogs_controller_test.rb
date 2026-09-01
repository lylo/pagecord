require "test_helper"

class Admin::Moderation::BlogsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    login_as users(:joel)
    Blog.update_all(reviewed_at: Time.current)
    @blog = blogs(:annie)
    @blog.update!(reviewed_at: nil)
  end

  test "lists blogs that have not been reviewed" do
    get admin_moderation_blogs_path

    assert_response :success
    assert_match "@#{@blog.subdomain}", response.body
  end

  test "leaves out blogs that have been reviewed" do
    get admin_moderation_blogs_path

    assert_no_match "@#{blogs(:vivian).subdomain}", response.body
  end

  test "leaves out blogs whose user has been discarded" do
    @blog.user.discard!

    get admin_moderation_blogs_path

    assert_no_match "@#{@blog.subdomain}", response.body
  end

  test "links each blog to its admin account page" do
    get admin_moderation_blogs_path

    assert_match admin_user_path(@blog.user), response.body
  end
end
