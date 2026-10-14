require "test_helper"

class User::InvitableTest < ActiveSupport::TestCase
  test "admins can invite without limit" do
    assert_equal Float::INFINITY, users(:joel).invitations_remaining
  end

  test "subscribers have ten invitations" do
    user = users(:annie)
    user.invitations.create!

    assert_equal 9, user.invitations_remaining
  end

  test "free writers have none until they have posted on four different days" do
    user = users(:joel)
    user.update!(admin: false)
    user.subscription.destroy!
    user.reload

    assert_equal 0, user.invitations_remaining

    user.blog.posts.each_with_index { |post, index| post.update_column(:created_at, index.days.ago) }

    assert_equal 1, user.invitations_remaining, "three earned, two already created"
  end

  test "drafts don't earn invitations" do
    user = users(:joel)
    user.update!(admin: false)
    user.subscription.destroy!
    user.blog.posts.each_with_index { |post, index| post.update_columns(created_at: index.days.ago, status: :draft) }

    assert_equal 0, user.reload.invitations_remaining
  end
end
