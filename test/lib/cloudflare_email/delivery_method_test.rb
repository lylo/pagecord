require "test_helper"

class CloudflareEmail::DeliveryMethodTest < ActiveSupport::TestCase
  setup do
    @delivery_method = CloudflareEmail::DeliveryMethod.new(api_token: "token", account_id: "account")
  end

  test "payload includes raw mime message and envelope recipients" do
    mail = Mail.new do
      from "Pagecord <hello@cfmail.pagecord.com>"
      to "reader@example.com"
      cc "copy@example.com"
      subject "Hello"
      body "Plain body"
    end

    payload = @delivery_method.send(:payload, mail)

    assert_equal "hello@cfmail.pagecord.com", payload[:from]
    assert_equal [ "reader@example.com", "copy@example.com" ], payload[:recipients]
    assert_includes payload[:mime_message], "Subject: Hello"
    assert_includes payload[:mime_message], "Plain body"
  end
end
