require "test_helper"

class ChurnTest < ActiveSupport::TestCase
  setup do
    @user = users(:joel)
    @subscription = subscriptions(:one)
  end

  test "record denormalises everything worth keeping" do
    @user.update!(signup_referrer: "https://news.ycombinator.com/")

    churn = Churn.record(@user, :subscription_cancelled)

    assert_equal @user.id, churn.user_id
    assert_equal "subscription_cancelled", churn.kind
    assert_equal "annual", churn.plan
    assert_equal 2000, churn.unit_price
    assert_equal @subscription.paddle_subscription_id, churn.paddle_subscription_id
    assert_equal @user.blog.subdomain, churn.blog_subdomain
    assert_equal "https://news.ycombinator.com/", churn.signup_referrer
    assert_equal @user.created_at, churn.signed_up_at
    assert_equal @subscription.created_at, churn.subscribed_at
    assert_equal @user.blog.posts.count, churn.posts_count
  end

  test "record is idempotent for the same departure" do
    Churn.record(@user, :subscription_cancelled)

    assert_no_difference -> { Churn.count } do
      Churn.record(@user, :subscription_cancelled)
    end
  end

  test "record captures a free user with no subscription" do
    user = users(:vivian)

    churn = Churn.record(user, :account_deleted)

    assert_nil churn.plan
    assert_nil churn.unit_price
    assert_nil churn.paddle_subscription_id
    assert_equal user.created_at, churn.signed_up_at
  end

  test "record accepts an explicit occurred_at" do
    churn = Churn.record(@user, :account_deleted, occurred_at: 3.days.ago)

    assert_in_delta 3.days.ago, churn.occurred_at, 1.second
  end

  test "survives the account it describes being destroyed" do
    churn = Churn.record(@user, :account_deleted)

    @user.destroy!

    assert_equal @user.id, churn.reload.user_id
    assert_nil churn.user
  end
end
