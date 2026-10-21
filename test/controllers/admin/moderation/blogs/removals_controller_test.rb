require "test_helper"

class Admin::Moderation::Blogs::RemovalsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest
  include ActiveJob::TestHelper

  setup do
    login_as users(:joel)
  end

  test "discards the user without calling it spam" do
    blog = blogs(:elliot)
    blog.update!(reviewed_at: nil)

    assert_enqueued_with(job: DestroyUserJob, args: [ blog.user.id, { reason: :admin_deleted } ]) do
      post admin_moderation_blog_removal_path(blog)
    end

    assert_redirected_to admin_moderation_blogs_path
    assert_not_nil blog.reload.reviewed_at
  end
end
