require "test_helper"
require "mocha/minitest"

class PostmarkBatchSenderTest < ActiveSupport::TestCase
  test "BATCH_SIZE is 50" do
    assert_equal 50, PostmarkBatchSender::BATCH_SIZE
  end

  test "send_batch returns results for each message" do
    sender = PostmarkBatchSender.new
    subscriber = email_subscribers(:one)
    digest = post_digests(:one)

    message = PostDigestMailer.with(digest: digest, subscriber: subscriber).weekly_digest
    messages_with_subscribers = [ [ message, subscriber ] ]

    mock_client = mock("postmark_client")
    mock_client.expects(:deliver_messages).returns([ { error_code: 0, message: "OK" } ])
    Postmark::ApiClient.stubs(:new).returns(mock_client)

    results = sender.send_batch(messages_with_subscribers)

    assert_equal 1, results.size
    assert_equal subscriber, results.first.subscriber
    assert results.first.success
  end

  test "send_batch handles failed deliveries" do
    sender = PostmarkBatchSender.new
    subscriber = email_subscribers(:one)
    digest = post_digests(:one)

    message = PostDigestMailer.with(digest: digest, subscriber: subscriber).weekly_digest
    messages_with_subscribers = [ [ message, subscriber ] ]

    mock_client = mock("postmark_client")
    mock_client.expects(:deliver_messages).returns([ { error_code: 406, message: "Inactive recipient" } ])
    Postmark::ApiClient.stubs(:new).returns(mock_client)

    results = sender.send_batch(messages_with_subscribers)

    assert_equal 1, results.size
    assert_equal subscriber, results.first.subscriber
    refute results.first.success
    assert_equal "Inactive recipient", results.first.error_message
  end
end
