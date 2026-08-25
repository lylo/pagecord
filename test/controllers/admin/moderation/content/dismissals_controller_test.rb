require "test_helper"

class Admin::Moderation::Content::DismissalsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    login_as users(:joel)
  end

  test "restores a discarded post and marks its moderation clean" do
    moderation = content_moderations(:flagged_spam)
    post_record = moderation.post
    post_record.discard!

    post admin_moderation_content_dismissal_path(post_record.token)

    assert_redirected_to admin_moderation_content_index_path
    assert_not post_record.reload.discarded?
    assert moderation.reload.clean?
  end
end
