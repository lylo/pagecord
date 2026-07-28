require "test_helper"

class App::Comments::ApprovalsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @user = users(:joel)
    @post = posts(:one)
    login_as @user
  end

  test "approves a comment, leaving no reply behind" do
    comment = post_comments(:pending)

    assert_no_difference "Post::Comment.count" do
      post app_comment_approval_path(comment)
    end

    assert_redirected_to app_comments_path
    assert comment.reload.approved?
  end

  test "approves and replies in one go" do
    comment = post_comments(:pending)

    assert_difference "Post::Comment.count", 1 do
      post app_comment_approval_path(comment), params: { comment: { message: "Thanks for this!" } }
    end

    assert comment.reload.approved?
    reply = comment.replies.sole
    assert reply.author?
    assert reply.approved?
    assert_equal "Thanks for this!", reply.message
    assert_equal 5, @post.reload.comments_count, "both the comment and the reply become public"
  end

  test "a rejected reply leaves the comment unapproved" do
    comment = post_comments(:pending)

    assert_no_difference "Post::Comment.count" do
      post app_comment_approval_path(comment), params: { comment: { message: "x" * 9.kilobytes } }
    end

    assert_not comment.reload.approved?, "approving and replying succeed or fail together"
    assert_redirected_to app_comment_path(comment)
  end

  test "approves inline and refreshes the moderation list and nav count" do
    comment = post_comments(:pending)

    post app_comment_approval_path(comment), params: { comment: { message: "" } }, as: :turbo_stream

    assert_response :success
    assert comment.reload.approved?
    assert_select "turbo-stream[action=update][target=comments_moderation]"
    assert_select "turbo-stream[action=update][target=comments_nav_pending_count]"
    assert_select "turbo-stream[action=update][target=flash]", text: /Comment approved/
  end

  test "shows an inline reply error without approving the comment" do
    comment = post_comments(:pending)

    post app_comment_approval_path(comment),
      params: { comment: { message: "x" * 9.kilobytes } },
      as: :turbo_stream

    assert_response :unprocessable_entity
    assert_not comment.reload.approved?
    assert_select "turbo-stream[action=replace][target=post_comment_#{comment.id}]"
    assert_includes response.body, "Message is too long"
  end

  # blog.updated_at rolls the fragment key, the ETag and the Cloudflare cache tag
  test "approving invalidates the cached post page" do
    was = blogs(:joel).updated_at

    travel 1.second do
      post app_comment_approval_path(post_comments(:pending))
    end

    assert_operator blogs(:joel).reload.updated_at, :>, was
  end

  test "can't touch another blog's comments" do
    blogs(:annie).update!(comments_enabled: true)
    users(:annie).update!(features: [ "comments" ])
    login_as users(:annie)

    post app_comment_approval_path(post_comments(:pending))

    assert_response :not_found
    assert_not post_comments(:pending).reload.approved?
  end
end
