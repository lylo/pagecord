require "test_helper"

class SubscriptionsHelperTest < ActionView::TestCase
  test "a price shows cents only when it has them" do
    assert_equal "$29", subscription_price(Subscription.new(unit_price: 2900))
    assert_equal "$42.46", subscription_price(Subscription.new(unit_price: 4246))
  end
end
