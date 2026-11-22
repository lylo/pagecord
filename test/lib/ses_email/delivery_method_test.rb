require "test_helper"

class SesEmail::DeliveryMethodTest < ActiveSupport::TestCase
  test "deliver! sends the raw message through SES to every envelope recipient" do
    mail = Mail.new(from: "digest@newsletters.pagecord.com", to: "reader@example.com", bcc: "hidden@example.com", subject: "Hello", body: "Body")
    client = mock("ses_client")
    Aws::SESV2::Client.stubs(:new).returns(client)

    client.expects(:send_email).with { |args|
      raw = args.dig(:content, :raw, :data)
      args.dig(:destination, :to_addresses) == [ "reader@example.com", "hidden@example.com" ] &&
        raw.include?("To: reader@example.com") && raw.include?("Subject: Hello") && raw.exclude?("hidden@example.com")
    }

    SesEmail::DeliveryMethod.new({}).deliver!(mail)
  end
end
