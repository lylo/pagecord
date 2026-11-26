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

  test "reviewing again keeps the original review date" do
    assert_no_changes -> { blogs(:elliot).reload.reviewed_at } do
      post admin_moderation_blog_review_path(blogs(:elliot))
    end
  end

  test "a blank blog can't be reviewed" do
    post admin_moderation_blog_review_path(blogs(:unengaged))

    assert_response :not_found
    assert_nil blogs(:unengaged).reload.reviewed_at
  end
end
