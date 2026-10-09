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

  test "an invalid recipient is undeliverable" do
    respond_with "400", success: false, errors: [ { code: 10202, message: "email.invalid" } ]

    assert_raises(CloudflareEmail::UndeliverableError) { @delivery_method.deliver!(mail) }
  end

  test "any other rejected request raises so it is retried and reported" do
    respond_with "400", success: false, errors: [ { code: 10001, message: "invalid_request_schema" } ]

    error = assert_raises(CloudflareEmail::DeliveryError) { @delivery_method.deliver!(mail) }
    assert_not_kind_of CloudflareEmail::UndeliverableError, error
  end

  test "a suppressed recipient is undeliverable" do
    respond_with "200", success: true, result: { delivered: [], suppressed_recipients: [ "reader@example.com" ] }

    assert_raises(CloudflareEmail::UndeliverableError) { @delivery_method.deliver!(mail) }
  end

  test "a throttled request can be retried" do
    respond_with "429", success: false, errors: [ { code: 10004, message: "email.sending.error.throttled" } ]

    error = assert_raises(CloudflareEmail::DeliveryError) { @delivery_method.deliver!(mail) }
    assert_not_kind_of CloudflareEmail::UndeliverableError, error
  end

  test "a delivered message does not raise" do
    respond_with "200", success: true, result: { delivered: [ "reader@example.com" ], suppressed_recipients: [], permanent_bounces: [] }

    assert_nothing_raised { @delivery_method.deliver!(mail) }
  end

  private

    def mail
      Mail.new(from: "hello@cfmail.pagecord.com", to: "reader@example.com", subject: "Hello", body: "Plain body")
    end

    def respond_with(code, body)
      Net::HTTP.any_instance.stubs(:request).returns(stub(code: code, body: body.to_json))
    end
end
