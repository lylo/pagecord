require "test_helper"

class AccountTombstoneTest < ActiveSupport::TestCase
  test "records dates and plan for a voluntary deletion, but names no blog" do
    user = users(:annie)

    tombstone = AccountTombstone.record!(user, reason: :user_deleted)

    assert tombstone.user_deleted?
    assert_equal user.created_at, tombstone.signed_up_at
    assert_nil tombstone.subdomain
  end

  test "names the blogs on a spam deletion" do
    user = users(:annie)

    tombstone = AccountTombstone.record!(user, reason: :spam)

    assert tombstone.spam?
    assert_equal user.blogs.pluck(:subdomain).join(" "), tombstone.subdomain
  end

  test "records the plan of a paying account" do
    tombstone = AccountTombstone.record!(users(:joel), reason: :user_deleted)

    assert_equal users(:joel).subscription.plan, tombstone.plan
  end

  test "a returning spammer gets a second tombstone rather than a collision" do
    user = users(:annie)

    AccountTombstone.record!(user, reason: :spam)

    assert_difference -> { AccountTombstone.count }, 1 do
      AccountTombstone.record!(user, reason: :spam)
    end
  end

  test "restoring the account removes its tombstone" do
    user = users(:annie)
    AccountTombstone.record!(user, reason: :spam)
    user.discard!

    assert_difference -> { AccountTombstone.count }, -1 do
      user.undiscard!
    end
  end

  test "restoring one account leaves another's tombstone alone" do
    AccountTombstone.record!(users(:annie), reason: :spam)
    other = users(:vivian)
    other.discard!

    assert_no_difference -> { AccountTombstone.count } do
      other.undiscard!
    end
  end
end
