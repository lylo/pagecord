require "test_helper"
require "mocha/minitest"

class PostDigest::PostmarkDeliveryTest < ActiveSupport::TestCase
  test "BATCH_SIZE is 50" do
    assert_equal 50, PostDigest::PostmarkDelivery::BATCH_SIZE
  end

  test "deliver_all creates delivery records for each subscriber" do
    blog = blogs(:joel)
    subscriber = email_subscribers(:one)
    post = blog.posts.create!(title: "New Post", content: "Content")
    digest = PostDigest.generate_for(blog)

    mock_client = mock("postmark_client")
    mock_client.expects(:deliver_messages).returns([ { error_code: 0, message: "OK" } ])
    Postmark::ApiClient.stubs(:new).returns(mock_client)

    delivery = PostDigest::PostmarkDelivery.new(digest)

    assert_difference "PostDigestDelivery.count", 1 do
      delivery.deliver_all
    end

    assert digest.deliveries.exists?(email_subscriber: subscriber)
  end

  test "deliver_all handles failed deliveries without creating records" do
    blog = blogs(:joel)
    subscriber = email_subscribers(:one)
    post = blog.posts.create!(title: "New Post", content: "Content")
    digest = PostDigest.generate_for(blog)

    mock_client = mock("postmark_client")
    mock_client.expects(:deliver_messages).returns([ { error_code: 406, message: "Inactive recipient" } ])
    Postmark::ApiClient.stubs(:new).returns(mock_client)

    delivery = PostDigest::PostmarkDelivery.new(digest)

    assert_no_difference "PostDigestDelivery.count" do
      delivery.deliver_all
    end
  end

  test "deliver_all skips subscribers who already received the digest" do
    blog = blogs(:joel)
    subscriber = email_subscribers(:one)
    post = blog.posts.create!(title: "New Post", content: "Content")
    digest = PostDigest.generate_for(blog)
    digest.deliveries.create!(email_subscriber: subscriber, delivered_at: Time.current)

    mock_client = mock("postmark_client")
    Postmark::ApiClient.stubs(:new).returns(mock_client)

    delivery = PostDigest::PostmarkDelivery.new(digest)

    assert_no_difference "PostDigestDelivery.count" do
      delivery.deliver_all
    end
  end
end
