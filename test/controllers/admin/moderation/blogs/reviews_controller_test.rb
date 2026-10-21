require "test_helper"

class Admin::Moderation::Blogs::ReviewsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    login_as users(:joel)
  end

  test "marks the blog reviewed" do
    blog = blogs(:elliot)
    blog.update!(reviewed_at: nil)

    post admin_moderation_blog_review_path(blog)

    assert_redirected_to admin_moderation_blogs_path
    assert_not_nil blog.reload.reviewed_at
  end

  test "takes the blog out of the queue in place" do
    blog = blogs(:elliot)
    blog.update!(reviewed_at: nil)

    post admin_moderation_blog_review_path(blog, filter: "posts"), as: :turbo_stream

    assert_response :success
    assert_select "turbo-stream[action=remove][target=?]", dom_id(blog)
    assert_select "turbo-stream[target=moderation_filters] .btn-group-item-active", text: /Posts/
  end
end
