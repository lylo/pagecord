require "test_helper"
require "mocha/minitest"

class PostDigest::DeliveryJobTest < ActiveJob::TestCase
  setup do
    @blog = blogs(:joel)
    @subscriber = email_subscribers(:one)
  end

  test "creates deliveries for pending subscribers" do
    post = @blog.posts.create!(title: "New Post", content: "Content")
    digest = PostDigest.generate_weekly_digest_for(@blog)

    assert_difference "PostDigestDelivery.count", 1 do
      PostDigest::DeliveryJob.perform_now(digest.id)
    end

    assert digest.deliveries.exists?(email_subscriber: @subscriber)
    assert digest.reload.delivered_at.present?
  end

  test "skips subscribers who already received the digest" do
    post = @blog.posts.create!(title: "New Post", content: "Content")
    digest = PostDigest.generate_weekly_digest_for(@blog)
    digest.deliveries.create!(email_subscriber: @subscriber, delivered_at: Time.current)

    assert_no_difference "PostDigestDelivery.count" do
      PostDigest::DeliveryJob.perform_now(digest.id)
    end
  end

  test "handles multiple subscribers in batches" do
    post = @blog.posts.create!(title: "New Post", content: "Content")

    @blog.email_subscribers.create!(email: "sub2@example.com", confirmed_at: Time.current)
    @blog.email_subscribers.create!(email: "sub3@example.com", confirmed_at: Time.current)

    digest = PostDigest.generate_weekly_digest_for(@blog)

    assert_difference "PostDigestDelivery.count", 3 do
      PostDigest::DeliveryJob.perform_now(digest.id)
    end
  end

  test "delivers individual digest" do
    post = @blog.posts.create!(title: "Individual Post", content: "Content")
    digest = PostDigest.generate_individual_for(post)

    assert_difference "PostDigestDelivery.count", 1 do
      PostDigest::DeliveryJob.perform_now(digest.id)
    end

    assert digest.reload.delivered_at.present?
  end

  test "in production, delivers via Postmark by default" do
    digest = PostDigest.create!(blog: @blog, kind: :individual)
    Rails.env.stubs(:production?).returns(true)

    PostDigest::PostmarkDelivery.any_instance.expects(:deliver_all)
    PostDigest::DeliveryJob.perform_now(digest.id)
  end

  test "in production, delivers via SES for users with the feature" do
    digest = PostDigest.create!(blog: @blog, kind: :individual)
    @blog.user.update!(features: [ "ses_newsletter_delivery" ])
    Rails.env.stubs(:production?).returns(true)

    PostDigest::SesDelivery.any_instance.expects(:deliver_all)
    PostDigest::DeliveryJob.perform_now(digest.id)
  end

  test "a paused SES account discards the job and reports it" do
    digest = PostDigest.create!(blog: @blog, kind: :individual)
    @blog.user.update!(features: [ "ses_newsletter_delivery" ])
    Rails.env.stubs(:production?).returns(true)
    PostDigest::SesDelivery.any_instance.stubs(:deliver_all).raises(Aws::SESV2::Errors::SendingPausedException.new(nil, "paused"))
    Rails.error.expects(:report)

    assert_nothing_raised { PostDigest::DeliveryJob.perform_now(digest.id) }
  end
end
