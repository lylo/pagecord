require "test_helper"

class App::Comments::RepliesControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @post = posts(:one)
    @user.update!(features: @user.features | [ "comments" ])
    login_as @user
  end

  test "posts an author reply that is approved immediately" do
    parent = @post.comments.create!(name: "Reader", message: "A question", approved_at: Time.current)

    assert_difference "Post::Comment.count", 1 do
      post app_comment_replies_path(parent), params: { comment: { message: "Thanks!" } }
    end

    reply = parent.replies.sole
    assert reply.author?
    assert reply.approved?
  end

  test "does not post an author reply to a pending comment" do
    comment = post_comments(:pending)

    assert_no_difference "Post::Comment.count" do
      post app_comment_replies_path(comment), params: { comment: { message: "Too soon" } }
    end

    assert_response :not_found
    assert_not comment.reload.approved?
  end

  test "refuses a second author reply to the same comment" do
    assert_no_difference "Post::Comment.count" do
      post app_comment_replies_path(post_comments(:approved)), params: { comment: { message: "Again" } }
    end

    assert_redirected_to app_comment_path(post_comments(:approved))
  end

  # The one-reply rule means an unremovable reply would be permanent
  test "deletes a reply and returns to its comment so another can be written" do
    reply = post_comments(:author_reply)

    assert_difference "Post::Comment.count", -1 do
      delete app_comment_reply_path(post_comments(:approved), reply)
    end

    assert_redirected_to app_comment_path(post_comments(:approved))

    get app_comment_path(post_comments(:approved))
    assert_select "textarea", 1, "the reply box should come back"
  end
end
