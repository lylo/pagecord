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
end
