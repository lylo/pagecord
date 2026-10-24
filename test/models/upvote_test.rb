require "test_helper"

class UpvoteTest < ActiveSupport::TestCase
  test "should not touch post on create" do
    post = posts(:two)
    original_updated_at = post.updated_at

    travel 1.minute do
      post.upvotes.create! hash_id: SecureRandom.hex
    end

    assert_equal original_updated_at, post.reload.updated_at
  end
end
