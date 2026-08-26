require "test_helper"

class Admin::Moderation::Spam::DetectionRunsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest
  include ActiveJob::TestHelper

  setup do
    login_as users(:joel)
  end

  test "queues a detection run" do
    assert_enqueued_with(job: SpamDetectionJob) do
      post admin_moderation_spam_detection_run_path
    end

    assert_redirected_to admin_moderation_spam_index_path
  end
end
