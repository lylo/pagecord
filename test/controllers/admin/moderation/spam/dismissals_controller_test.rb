require "test_helper"

class Admin::Moderation::Spam::DismissalsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    login_as users(:joel)
  end

  test "marks the detection clean and reviewed" do
    detection = spam_detections(:spam_blog_detection)

    post admin_moderation_spam_dismissal_path(detection)

    assert_redirected_to admin_moderation_spam_index_path
    detection.reload
    assert detection.clean?
    assert_not_nil detection.reviewed_at
  end
end
