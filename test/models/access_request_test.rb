require "test_helper"

class AccessRequestTest < ActiveSupport::TestCase
  test "stores a digest of the token, which finds the request" do
    request = AccessRequest.create!(user: users(:joel))

    assert_not_equal request.token, request.token_digest
    assert_equal request, AccessRequest.find_by_token(request.token)
    assert_nil AccessRequest.find_by_token(request.token_digest)
  end

  test "sets expiration on creation" do
    request = AccessRequest.new(user: users(:joel))
    request.save!

    assert_not_nil request.expires_at
    assert_in_delta 1.day.from_now, request.expires_at, 5.seconds
  end
end
