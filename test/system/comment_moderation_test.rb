require "application_system_test_case"

class CommentModerationTest < ApplicationSystemTestCase
  setup do
    @comment = post_comments(:approved)

    access_request = users(:joel).access_requests.create!
    visit access_request_verification_path(token: access_request.token_digest)
  end

  # turbo_confirm only works when Turbo drives the form, so this page must not
  # opt out of Turbo: with data-turbo=false the buttons deleted with no dialog.
  test "deleting a comment asks first and honours the answer" do
    visit app_comment_path(@comment)

    dismiss_confirm { click_on "Delete" }
    assert Post::Comment.exists?(@comment.id), "dismissing the dialog should keep the comment"

    accept_confirm { click_on "Delete" }
    assert_current_path app_comments_path, wait: 5
    assert_text "Comment deleted"
    assert_not Post::Comment.exists?(@comment.id)
  end

  test "approving with a reply publishes both" do
    pending = post_comments(:unanswered)
    pending.update!(approved_at: nil)

    visit app_comment_path(pending)
    fill_in "comment[message]", with: "Thanks for reading!"
    click_on "Approve"

    assert_current_path app_comments_path, wait: 5
    assert_text "Comment approved"
    assert pending.reload.approved?
  end
end
