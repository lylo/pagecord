require "test_helper"

class Admin::Moderation::Blogs::SpamConfirmationsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest
  include ActiveJob::TestHelper

  setup do
    login_as users(:joel)
  end

  test "queues user destruction, which records the spam verdict" do
    blog = blogs(:elliot)

    assert_enqueued_with(job: DestroyUserJob, args: [ blog.user.id, { reason: :spam } ]) do
      post admin_moderation_blog_spam_confirmation_path(blog)
    end

    assert_redirected_to admin_moderation_blogs_path
  end

  test "the blog is gone from the reloaded page before the job has run" do
    blog = blogs(:elliot)
    blog.update!(reviewed_at: nil)

    post admin_moderation_blog_spam_confirmation_path(blog)
    follow_redirect!

    assert_no_match admin_moderation_blog_review_path(blog), response.body
    assert_not blog.user.reload.discarded?
  end
end
