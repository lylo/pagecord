require "test_helper"

class FollowingTest < ActiveSupport::TestCase
  test "following" do
    assert users(:joel).following?(blogs(:vivian))
    assert users(:joel).following?(blogs(:annie))
  end
end
