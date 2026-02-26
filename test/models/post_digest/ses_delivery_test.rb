require "test_helper"
require "mocha/minitest"

class PostDigest::SesDeliveryTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
    @subscriber = email_subscribers(:one)
    @post = @blog.posts.create!(title: "SES Test Post", content: "Content")
    @digest = PostDigest.generate_weekly_digest_for(@blog)

    @mock_client = mock("ses_client")
    Aws::SESV2::Client.stubs(:new).returns(@mock_client)
  end

  test "BATCH_SIZE is 50" do
    assert_equal 50, PostDigest::SesDelivery::BATCH_SIZE
  end

  test "deliver_all creates delivery and event records" do
    @mock_client.expects(:send_email).returns(
      OpenStruct.new(message_id: "ses-msg-001")
    )

    delivery = PostDigest::SesDelivery.new(@digest)

    assert_difference [ "PostDigestDelivery.count", "Email::Event.count" ], 1 do
      delivery.deliver_all
    end

    assert @digest.deliveries.exists?(email_subscriber: @subscriber)
    assert @digest.reload.delivered_at?

    event = Email::Event.last
    assert_equal "ses-msg-001", event.message_id
    assert_equal "ses", event.provider
    assert_equal "sent", event.status
  end

  test "deliver_all skips suppressed emails" do
    Email::Suppression.suppress!(@subscriber.email, reason: "bounce", bounce_type: "Permanent")

    delivery = PostDigest::SesDelivery.new(@digest)

    assert_no_difference [ "PostDigestDelivery.count", "Email::Event.count" ] do
      delivery.deliver_all
    end

    assert @digest.reload.delivered_at?
  end

  test "deliver_all skips already-delivered subscribers" do
    @digest.deliveries.create!(email_subscriber: @subscriber, delivered_at: Time.current)

    delivery = PostDigest::SesDelivery.new(@digest)

    assert_no_difference "PostDigestDelivery.count" do
      delivery.deliver_all
    end

    assert @digest.reload.delivered_at?
  end

  test "deliver_all handles rejected messages gracefully" do
    @mock_client.expects(:send_email).raises(
      Aws::SESV2::Errors::MessageRejected.new(nil, "Email address is on the suppression list")
    )

    delivery = PostDigest::SesDelivery.new(@digest)

    assert_no_difference [ "PostDigestDelivery.count", "Email::Event.count" ] do
      delivery.deliver_all
    end

    assert @digest.reload.delivered_at?
  end

  test "deliver_all uses individual mailer action for individual digests" do
    digest = PostDigest.create!(blog: @blog, kind: :individual)
    digest.digest_posts.create!(post: @post)

    @mock_client.expects(:send_email).returns(
      OpenStruct.new(message_id: "ses-msg-002")
    )

    assert_difference "PostDigestDelivery.count", 1 do
      PostDigest::SesDelivery.new(digest).deliver_all
    end

    assert digest.reload.delivered_at?
  end

  test "deliver_all uses send.pagecord.com as sender domain" do
    captured_args = nil
    @mock_client.expects(:send_email).with { |args|
      captured_args = args
      true
    }.returns(OpenStruct.new(message_id: "ses-msg-003"))

    PostDigest::SesDelivery.new(@digest).deliver_all

    assert_match /send\.pagecord\.com/, captured_args[:from_email_address]
  end

  test "deliver_with_failover retries on service error" do
    primary_client = mock("primary_ses_client")
    failover_client = mock("failover_ses_client")

    Aws::SESV2::Client.stubs(:new).with(has_entry(region: "eu-west-2")).returns(primary_client)
    Aws::SESV2::Client.stubs(:new).with(has_entry(region: "eu-west-1")).returns(failover_client)

    primary_client.expects(:send_email).raises(
      Aws::SESV2::Errors::ServiceUnavailableException.new(nil, "Service unavailable")
    )
    failover_client.expects(:send_email).returns(
      OpenStruct.new(message_id: "ses-failover-001")
    )

    assert_difference "PostDigestDelivery.count", 1 do
      PostDigest::SesDelivery.deliver_with_failover(@digest)
    end
  end
end
