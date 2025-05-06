require "test_helper"

class EmailChangeRequestTest < ActiveSupport::TestCase
  test "generates a token on creation" do
    request = EmailChangeRequest.new(user: users(:joel), new_email: "new_email@example.com")
    request.save!

    assert_not_nil request.token_digest
  end

  test "sets expiration on creation" do
    request = EmailChangeRequest.new(user: users(:joel), new_email: "new_email@example.com")
    request.save!

    assert_not_nil request.expires_at
    assert_in_delta 1.day.from_now, request.expires_at, 5.seconds
  end

  test "validates email format" do
    request = EmailChangeRequest.new(user: users(:joel), new_email: "invalid-email")
    assert_not request.valid?
    assert_includes request.errors[:new_email], "is invalid"
  end

  test "active scope includes only non-expired requests" do
    expired_request = EmailChangeRequest.create!(
      user: users(:joel),
      new_email: "expired@example.com",
      expires_at: 2.days.ago
    )

    active_request = EmailChangeRequest.create!(
      user: users(:joel),
      new_email: "active@example.com"
    )

    assert_includes EmailChangeRequest.active, active_request
    assert_not_includes EmailChangeRequest.active, expired_request
  end

  test "pending scope includes only requests without accepted_at" do
    pending_request = EmailChangeRequest.create!(
      user: users(:joel),
      new_email: "pending@example.com"
    )

    accepted_request = EmailChangeRequest.create!(
      user: users(:joel),
      new_email: "accepted@example.com",
      accepted_at: Time.current
    )

    assert_includes EmailChangeRequest.pending, pending_request
    assert_not_includes EmailChangeRequest.pending, accepted_request
  end

  test "accept! marks the request as accepted" do
    request = EmailChangeRequest.create!(
      user: users(:joel),
      new_email: "to_accept@example.com"
    )

    assert_nil request.accepted_at
    request.accept!
    assert_not_nil request.accepted_at
  end
end
