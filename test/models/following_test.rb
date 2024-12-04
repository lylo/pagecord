require "test_helper"

class FollowingTest < ActiveSupport::TestCase
  test "following" do
    assert users(:joel).following?(users(:vivian))
    assert users(:joel).following?(users(:annie))
  end
end
