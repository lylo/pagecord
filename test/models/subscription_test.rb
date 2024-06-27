require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase

  test "should be subscribed" do
    assert users(:joel).subscribed?
  end

  test "should not be subscribed" do
    assert_not users(:vivian).subscribed?
  end
end
