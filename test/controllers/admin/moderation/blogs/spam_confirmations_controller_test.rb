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
end
