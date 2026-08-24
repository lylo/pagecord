require "test_helper"

class AccessRequestTest < ActiveSupport::TestCase
  test "generates a token on creation" do
    request = AccessRequest.new(user: users(:joel))
    request.save!

    assert_not_nil request.token_digest
  end

  test "sets expiration on creation" do
    request = AccessRequest.new(user: users(:joel))
    request.save!

    assert_not_nil request.expires_at
    assert_in_delta 1.day.from_now, request.expires_at, 5.seconds
  end
end
