require "test_helper"
require "mocha/minitest"

class DigestReplyMailboxTest < ActionMailbox::TestCase
  test "should forward reply to digest email to blog owner" do
    user = users(:joel)
    digest = post_digests(:one)
    subscriber_email = "fred@example.com"  # Use existing confirmed subscriber

    DigestReplyMailer.expects(:with).with(
      digest: digest,
      original_mail: anything
    ).returns(stub(forward_reply: stub(deliver_now: true)))

    receive_inbound_email_from_mail(
      to: "digest-reply-#{digest.masked_id}@post.pagecord.com",
      from: subscriber_email,
      subject: "Thanks for the great posts!",
      body: "Really enjoyed reading your latest digest."
    )
  end

  test "should not forward if digest not found" do
    DigestReplyMailer.expects(:forward_reply).never

    receive_inbound_email_from_mail(
      to: "digest-reply-invalidid@post.pagecord.com",
      from: "subscriber@example.com",
      subject: "Thanks for the great posts!",
      body: "Really enjoyed reading your latest digest."
    )
  end

  test "should not forward if sender is not a confirmed subscriber" do
    digest = post_digests(:one)

    DigestReplyMailer.expects(:forward_reply).never

    receive_inbound_email_from_mail(
      to: "digest-reply-#{digest.masked_id}@post.pagecord.com",
      from: "random@example.com",
      subject: "Thanks for the great posts!",
      body: "Really enjoyed reading your latest digest."
    )
  end

  test "should not forward if no from address" do
    digest = post_digests(:one)

    DigestReplyMailer.expects(:forward_reply).never

    receive_inbound_email_from_mail(
      to: "digest-reply-#{digest.masked_id}@post.pagecord.com",
      from: nil,
      subject: "Thanks for the great posts!",
      body: "Really enjoyed reading your latest digest."
    )
  end

  test "should handle malformed digest reply address" do
    DigestReplyMailer.expects(:forward_reply).never

    assert_raises ActionMailbox::Router::RoutingError do
      receive_inbound_email_from_mail(
        to: "digest-reply-@post.pagecord.com",
        from: "subscriber@example.com",
        subject: "Thanks for the great posts!",
        body: "Really enjoyed reading your latest digest."
      )
    end
  end

  test "should log error and capture exception if forwarding fails" do
    user = users(:joel)
    digest = post_digests(:one)
    subscriber_email = "fred@example.com"  # Use existing confirmed subscriber

    DigestReplyMailer.expects(:with).raises(StandardError.new("SMTP error"))
    Rails.logger.expects(:error).with(regexp_matches(/Unable to process digest reply/))
    Sentry.expects(:capture_exception)

    receive_inbound_email_from_mail(
      to: "digest-reply-#{digest.masked_id}@post.pagecord.com",
      from: subscriber_email,
      subject: "Thanks for the great posts!",
      body: "Really enjoyed reading your latest digest."
    )
  end
end
