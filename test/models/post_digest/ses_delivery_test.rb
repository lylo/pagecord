require "test_helper"
require "mocha/minitest"

class PostDigest::SesDeliveryTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
    @subscriber = email_subscribers(:one)
    @blog.posts.create!(title: "New Post", content: "Content")
    @digest = PostDigest.generate_weekly_digest_for(@blog)

    @client = mock("ses_client")
    Aws::SESV2::Client.stubs(:new).returns(@client)
  end

  test "deliver_all sends raw MIME per subscriber, records the delivery and marks the digest delivered" do
    @client.expects(:send_email).with { |args|
      raw = args.dig(:content, :raw, :data)
      raw.include?("<digest@newsletters.pagecord.com>") && raw.include?("To: #{@subscriber.email}")
    }.returns(stub(message_id: "ses-1"))

    assert_difference "PostDigestDelivery.count", 1 do
      PostDigest::SesDelivery.new(@digest).deliver_all
    end

    assert @digest.deliveries.exists?(email_subscriber: @subscriber)
    assert @digest.reload.delivered_at?
  end

  test "deliver_all reports a rejected message, skips it and still marks the digest delivered" do
    @client.expects(:send_email).raises(Aws::SESV2::Errors::MessageRejected.new(nil, "suppressed"))
    Rails.error.expects(:report)

    assert_no_difference "PostDigestDelivery.count" do
      PostDigest::SesDelivery.new(@digest).deliver_all
    end

    assert @digest.reload.delivered_at?
  end

  test "deliver_all skips subscribers who already received the digest" do
    @digest.deliveries.create!(email_subscriber: @subscriber, delivered_at: Time.current)
    @client.expects(:send_email).never

    PostDigest::SesDelivery.new(@digest).deliver_all

    assert @digest.reload.delivered_at?
  end
end
