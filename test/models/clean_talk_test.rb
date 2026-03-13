require "test_helper"
require "mocha/minitest"

class CleanTalkTest < ActiveSupport::TestCase
  test "sends check_message request and returns parsed response" do
    response_body = { "allow" => 1, "comment" => "Allowed" }.to_json
    stub_response = stub(body: response_body)

    CleanTalk.expects(:post).with("/api2.0", body: {
      method_name: "check_message",
      auth_key: ENV["CLEANTALK_AUTH_KEY"],
      sender_email: "test@example.com",
      sender_nickname: "Test User",
      message: "Hello!"
    }.to_json, headers: { "Content-Type" => "application/json" }).returns(stub_response)

    result = CleanTalk.check_message(email: "test@example.com", nickname: "Test User", message: "Hello!")
    assert_equal 1, result["allow"]
    assert_equal "Allowed", result["comment"]
  end

  test "raises on network error" do
    CleanTalk.expects(:post).raises(Net::ReadTimeout.new("timed out"))

    assert_raises(Net::ReadTimeout) do
      CleanTalk.check_message(email: "test@example.com", nickname: "Test", message: "Hi")
    end
  end
end
