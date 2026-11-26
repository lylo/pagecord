require "test_helper"

class Admin::Moderation::BlankBlogsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    login_as users(:joel)
  end

  test "lists unreviewed blogs with nothing on them, without a not spam button" do
    blogs(:elliot).update!(reviewed_at: nil)

    get admin_moderation_blank_blogs_path

    assert_select "##{dom_id(blogs(:unengaged))}"
    assert_select "##{dom_id(blogs(:elliot))}", count: 0
    assert_select "form[action='#{admin_moderation_blog_review_path(blogs(:unengaged))}']", count: 0
  end
end
