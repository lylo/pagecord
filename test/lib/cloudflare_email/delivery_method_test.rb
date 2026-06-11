require "test_helper"

class CloudflareEmail::DeliveryMethodTest < ActiveSupport::TestCase
  setup do
    @delivery_method = CloudflareEmail::DeliveryMethod.new(api_token: "token", account_id: "account")
  end

  test "payload includes single part html body" do
    mail = Mail.new(
      from: "Pagecord <hello@cfmail.pagecord.com>",
      to: "reader@example.com",
      subject: "Hello",
      content_type: "text/html; charset=UTF-8",
      content_transfer_encoding: "quoted-printable",
      body: "<p>caf=C3=A9</p>"
    )

    payload = @delivery_method.send(:payload, mail)

    assert_equal "<p>café</p>", payload[:html]
    assert_equal Encoding::UTF_8, payload[:html].encoding
    assert_not payload.key?(:text)
  end
end
