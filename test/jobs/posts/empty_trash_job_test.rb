require "test_helper"

class Posts::EmptyTrashJobTest < ActiveJob::TestCase
  test "destroys posts discarded more than 30 days ago" do
    old_post = posts(:one)
    old_post.discard!
    old_post.update_columns(discarded_at: 31.days.ago)

    recent_post = posts(:two)
    recent_post.discard!
    recent_post.update_columns(discarded_at: 29.days.ago)

    assert_difference("Post.count", -1) do
      Posts::EmptyTrashJob.perform_now
    end

    assert_nil Post.find_by(id: old_post.id)
    assert Post.find_by(id: recent_post.id)
  end

  test "does not destroy non-discarded posts" do
    post = posts(:one)

    assert_no_difference("Post.count") do
      Posts::EmptyTrashJob.perform_now
    end

    assert Post.find_by(id: post.id)
  end
end
