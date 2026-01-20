require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should validate format of email" do
    user = User.new(email: "joel")
    assert_not user.valid?

    user = User.new(email: "joel@blah.blahhhhh")
    assert user.valid?
  end

  test "should store in lowercase" do
    user = User.create!(email: "nEwUser@NewUser.COM")
    assert_equal "newuser@newuser.com", user.email
  end

  test "should strip whitespace" do
    user = User.create!(email: "newuser@newuser.com ")
    assert_equal "newuser@newuser.com", user.email
  end

  test "should be search indexable if created_at is more than 1 week ago" do
    user = User.create!(email: "test@example.com", created_at: 2.weeks.ago)
    assert user.search_indexable?
  end

  test "should not be search indexable if created_at is less than 1 week ago" do
    user = User.create!(email: "test@example.com", created_at: 6.days.ago)
    assert_not user.search_indexable?
  end

  test "should be search indexable if created_at is less than 1 week ago but user subscribed" do
    user = users(:joel)
    user.update!(created_at: 6.days.ago)
    assert user.search_indexable?
  end

  # Free trial tests
  test "on_trial? returns true when user created within 14 days and not subscribed" do
    user = User.create!(email: "trial@example.com", created_at: 5.days.ago)
    assert user.on_trial?
  end

  test "on_trial? returns false when user is subscribed" do
    user = users(:joel) # has subscription
    user.update!(created_at: 5.days.ago)
    assert_not user.on_trial?
  end

  test "on_trial? returns false when user created more than 14 days ago" do
    user = users(:vivian) # no subscription
    assert_not user.on_trial?
  end

  test "trial_days_remaining returns correct number of days" do
    user = User.create!(email: "trial@example.com", trial_ends_at: 9.days.from_now.to_date)
    assert_equal 9, user.trial_days_remaining
  end

  test "trial_days_remaining returns 0 when not on trial" do
    user = users(:vivian) # created 30 days ago, no subscription
    assert_equal 0, user.trial_days_remaining
  end

  test "trial_days_remaining returns 0 when subscribed" do
    user = users(:joel) # has subscription
    user.update!(created_at: 5.days.ago)
    assert_equal 0, user.trial_days_remaining
  end

  test "on_free_plan? returns true when not subscribed and not on trial" do
    user = users(:vivian) # created 30 days ago, no subscription
    assert user.on_free_plan?
  end

  test "on_free_plan? returns false when subscribed" do
    user = users(:joel) # has subscription
    assert_not user.on_free_plan?
  end

  test "on_free_plan? returns false when on trial" do
    user = User.create!(email: "trial@example.com", created_at: 5.days.ago)
    assert_not user.on_free_plan?
  end
end
