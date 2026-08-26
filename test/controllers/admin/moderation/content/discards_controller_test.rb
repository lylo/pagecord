require "test_helper"

class Admin::Moderation::Content::DiscardsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    login_as users(:joel)
  end

  test "discards the post" do
    post_record = content_moderations(:flagged_spam).post

    post admin_moderation_content_discard_path(post_record.token)

    assert_redirected_to admin_moderation_content_index_path
    assert post_record.reload.discarded?
  end
end
