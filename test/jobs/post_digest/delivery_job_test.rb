require "test_helper"

class PostDigest::DeliveryJobTest < ActiveJob::TestCase
  setup do
    @blog = blogs(:joel)
    @subscriber = email_subscribers(:one)
  end

  test "creates deliveries for pending subscribers" do
    post = @blog.posts.create!(title: "New Post", content: "Content")
    digest = PostDigest.generate_for(@blog)

    assert_difference "PostDigestDelivery.count", 1 do
      PostDigest::DeliveryJob.perform_now(digest.id)
    end

    assert digest.deliveries.exists?(email_subscriber: @subscriber)
    assert digest.reload.delivered_at.present?
  end

  test "skips subscribers who already received the digest" do
    post = @blog.posts.create!(title: "New Post", content: "Content")
    digest = PostDigest.generate_for(@blog)
    digest.deliveries.create!(email_subscriber: @subscriber, delivered_at: Time.current)

    assert_no_difference "PostDigestDelivery.count" do
      PostDigest::DeliveryJob.perform_now(digest.id)
    end
  end

  test "handles multiple subscribers in batches" do
    post = @blog.posts.create!(title: "New Post", content: "Content")

    @blog.email_subscribers.create!(email: "sub2@example.com", confirmed_at: Time.current)
    @blog.email_subscribers.create!(email: "sub3@example.com", confirmed_at: Time.current)

    digest = PostDigest.generate_for(@blog)

    assert_difference "PostDigestDelivery.count", 3 do
      PostDigest::DeliveryJob.perform_now(digest.id)
    end
  end

  test "delivers individual digest" do
    post = @blog.posts.create!(title: "Individual Post", content: "Content")
    digest = PostDigest.send_individual(post)

    assert_difference "PostDigestDelivery.count", 1 do
      PostDigest::DeliveryJob.perform_now(digest.id)
    end

    assert digest.reload.delivered_at.present?
  end
end
