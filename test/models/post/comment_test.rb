require "test_helper"

class Post::CommentTest < ActiveSupport::TestCase
  setup do
    @post = posts(:one)
  end

  test "requires a name and a message" do
    comment = @post.comments.new

    assert_not comment.valid?
    assert_includes comment.errors[:name], "can't be blank"
    assert_includes comment.errors[:message], "can't be blank"
  end

  test "link must be an http url" do
    assert_not @post.comments.new(name: "T", message: "m", link: "javascript:alert(1)").valid?
    assert @post.comments.new(name: "T", message: "m", link: "https://example.com").valid?
    assert @post.comments.new(name: "T", message: "m", link: "").valid?
  end

  test "can't comment when the blog has comments disabled" do
    @post.blog.update!(comments_enabled: false)

    comment = @post.comments.new(name: "T", message: "m")

    assert_not comment.valid?
    assert_includes comment.errors[:post], "is not accepting comments"
  end

  test "can't comment on a closed thread" do
    @post.close_comments!

    comment = @post.comments.new(name: "T", message: "m")

    assert_not comment.valid?
    assert_includes comment.errors[:post], "is not accepting comments"
  end

  test "the author can still reply to a closed thread" do
    parent = @post.comments.create!(name: "Reader", message: "m", approved_at: Time.current)
    @post.close_comments!

    reply = @post.comments.new(name: "Joel", message: "m", parent: parent, author: true)

    assert reply.valid?
  end

  test "the author can only reply once to a comment" do
    second = @post.comments.new(name: "Joel", message: "and another thing", parent: post_comments(:approved), author: true)

    assert_not second.valid?
    assert_includes second.errors[:base], "You've already replied to this comment"
  end

  test "the database enforces one author reply per comment" do
    assert_raises ActiveRecord::RecordNotUnique do
      Post::Comment.insert_all! [
        {
          post_id: @post.id,
          parent_id: post_comments(:approved).id,
          name: "Joel",
          message: "and another thing",
          author: true,
          approved_at: Time.current,
          created_at: Time.current,
          updated_at: Time.current
        }
      ]
    end
  end

  test "replies can only be one level deep" do
    reply = @post.comments.new(name: "T", message: "m", parent: post_comments(:author_reply))

    assert_not reply.valid?
    assert_includes reply.errors[:parent], "can't be a reply itself"
  end

  test "replies must be on the same post" do
    reply = posts(:two).comments.new(name: "T", message: "m", parent: post_comments(:approved))

    assert_not reply.valid?
    assert_includes reply.errors[:parent], "must be on the same post"
  end

  test "approving updates the post's approved comment count" do
    comment = post_comments(:pending)

    assert_difference -> { @post.reload.comments_count }, 1 do
      comment.approve!
    end
  end

  test "deleting an approved comment takes its replies with it" do
    reply_id = post_comments(:author_reply).id

    assert_difference -> { @post.reload.comments_count }, -2 do
      post_comments(:approved).destroy!
    end

    assert_not Post::Comment.exists?(reply_id)
  end

  test "deleting a pending comment leaves the count alone" do
    assert_no_difference -> { @post.reload.comments_count } do
      post_comments(:pending).destroy!
    end
  end
end
