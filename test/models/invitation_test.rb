require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  test "a new invitation gets a code without look-alike characters that can be typed in any case" do
    invitation = users(:annie).invitations.create!

    assert_match(/\A[A-HJ-NP-Z2-9]{10}\z/, invitation.code)
    assert_equal invitation, Invitation.available.find_by(code: " #{invitation.code.downcase} ")
  end

  test "a redeemed invitation is no longer available" do
    assert_nil Invitation.available.find_by(code: invitations(:redeemed).code)
    assert_equal invitations(:unused), Invitation.available.find_by(code: invitations(:unused).code)
  end

  test "redeeming records when" do
    invitations(:unused).update!(invitee: users(:annie))

    assert invitations(:unused).redeemed_at.present?
  end

  test "codes stop working when the inviter's account is discarded" do
    users(:joel).discard!

    assert_nil Invitation.available.find_by(code: invitations(:unused).code)
  end

  test "a redeemed code stays redeemed when the invitee's account is purged" do
    users(:vivian).destroy!

    assert invitations(:redeemed).reload.redeemed_at.present?
    assert_nil Invitation.available.find_by(code: invitations(:redeemed).code)
  end
end
