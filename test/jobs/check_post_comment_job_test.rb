require "test_helper"

class CheckPostCommentJobTest < ActiveSupport::TestCase
  setup do
    @comment = post_comments(:pending)
  end

  test "destroys the comment when it looks like spam" do
    Post::Comment.any_instance.stubs(:spam?).returns(true)

    assert_difference "Post::Comment.count", -1 do
      CheckPostCommentJob.perform_now(@comment.id)
    end
  end

  test "leaves a clean comment pending for approval" do
    Post::Comment.any_instance.stubs(:spam?).returns(false)

    assert_no_difference "Post::Comment.count" do
      CheckPostCommentJob.perform_now(@comment.id)
    end

    assert_not @comment.reload.approved?
  end

  test "does nothing when the comment has already gone" do
    assert_nothing_raised do
      CheckPostCommentJob.perform_now(-1)
    end
  end
end
