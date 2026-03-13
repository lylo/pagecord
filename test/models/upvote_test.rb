require "test_helper"

class UpvoteTest < ActiveSupport::TestCase
  test "should correctly counter cache on create" do
    post = posts(:two)

    assert_difference -> { post.reload.upvotes_count }, 1 do
      post.upvotes.create! hash_id: SecureRandom.hex
    end
  end

  test "should correctly counter cache on destroy" do
    post = posts(:one)

    assert_difference -> { post.reload.upvotes_count }, -1 do
      post.upvotes.first.destroy
    end
  end

  test "should not touch post on create" do
    post = posts(:two)
    original_updated_at = post.updated_at

    travel 1.minute do
      post.upvotes.create! hash_id: SecureRandom.hex
    end

    assert_equal original_updated_at, post.reload.updated_at
  end
end
