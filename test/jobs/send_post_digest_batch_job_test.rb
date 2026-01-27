require "test_helper"
require "mocha/minitest"

class SendPostDigestBatchJobTest < ActiveJob::TestCase
  setup do
    @blog = blogs(:joel)
    @subscriber = email_subscribers(:one)
  end

  test "creates deliveries for pending subscribers" do
    post = @blog.posts.create!(title: "New Post", content: "Content")
    digest = PostDigest.generate_for(@blog)

    mock_client = mock("postmark_client")
    mock_client.expects(:deliver_messages).returns([ { error_code: 0, message: "OK" } ])
    Postmark::ApiClient.stubs(:new).returns(mock_client)

    assert_difference "PostDigestDelivery.count", 1 do
      SendPostDigestBatchJob.perform_now(digest.id)
    end

    assert digest.deliveries.exists?(email_subscriber: @subscriber)
  end

  test "skips subscribers who already received the digest" do
    post = @blog.posts.create!(title: "New Post", content: "Content")
    digest = PostDigest.generate_for(@blog)
    digest.deliveries.create!(email_subscriber: @subscriber, delivered_at: Time.current)

    assert_no_difference "PostDigestDelivery.count" do
      SendPostDigestBatchJob.perform_now(digest.id)
    end
  end

  test "logs errors for failed deliveries without creating delivery records" do
    post = @blog.posts.create!(title: "New Post", content: "Content")
    digest = PostDigest.generate_for(@blog)

    mock_client = mock("postmark_client")
    mock_client.expects(:deliver_messages).returns([ { error_code: 406, message: "Inactive recipient" } ])
    Postmark::ApiClient.stubs(:new).returns(mock_client)

    assert_no_difference "PostDigestDelivery.count" do
      SendPostDigestBatchJob.perform_now(digest.id)
    end
  end

  test "handles multiple subscribers in batches" do
    post = @blog.posts.create!(title: "New Post", content: "Content")

    @blog.email_subscribers.create!(email: "sub2@example.com", confirmed_at: Time.current)
    @blog.email_subscribers.create!(email: "sub3@example.com", confirmed_at: Time.current)

    digest = PostDigest.generate_for(@blog)

    mock_client = mock("postmark_client")
    mock_client.expects(:deliver_messages).returns([
      { error_code: 0, message: "OK" },
      { error_code: 0, message: "OK" },
      { error_code: 0, message: "OK" }
    ])
    Postmark::ApiClient.stubs(:new).returns(mock_client)

    assert_difference "PostDigestDelivery.count", 3 do
      SendPostDigestBatchJob.perform_now(digest.id)
    end
  end
end
