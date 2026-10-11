require "test_helper"
require "mocha/minitest"

class PaddleApiTest < ActiveSupport::TestCase
  test "a cancellation Paddle refuses raises" do
    HTTParty.stubs(:post).returns(stub(body: { error: { code: "subscription_locked_pending_changes", detail: "Pending changes" } }.to_json))

    error = assert_raises(PaddleApi::Error) { PaddleApi.new.cancel_subscription("sub_123") }
    assert_match "subscription_locked_pending_changes", error.message
  end

  test "a cancellation that times out raises" do
    HTTParty.stubs(:post).raises(Net::ReadTimeout)

    assert_raises(PaddleApi::Error) { PaddleApi.new.cancel_subscription("sub_123") }
  end

  test "a cancellation Paddle accepts returns its response" do
    HTTParty.stubs(:post).returns(stub(body: { data: { id: "sub_123" } }.to_json))

    assert_equal "sub_123", PaddleApi.new.cancel_subscription("sub_123").dig("data", "id")
  end
end
