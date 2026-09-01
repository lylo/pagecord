require "test_helper"

class Admin::Moderation::Spam::ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest
  include ActiveJob::TestHelper

  setup do
    login_as users(:joel)
  end

  test "marks the detection reviewed and queues user destruction" do
    detection = spam_detections(:spam_blog_detection)

    assert_enqueued_with(job: DestroyUserJob, args: [ detection.blog.user.id, { reason: :spam } ]) do
      post admin_moderation_spam_confirmation_path(detection)
    end

    assert_redirected_to admin_moderation_spam_index_path
    assert_not_nil detection.reload.reviewed_at
  end
end
