require "test_helper"

class Post::EmailableTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @blog = blogs(:joel)
    @blog.update!(email_subscriptions_enabled: true, email_delivery_mode: :individual)
    @post = @blog.posts.create!(title: "Test Post", content: "Test content")
  end

  test "emailed? returns false with no digests" do
    assert_not @post.emailed?
  end

  test "emailed? returns true with a delivered digest" do
    digest = PostDigest.create!(blog: @blog, kind: :individual, delivered_at: Time.current)
    digest.digest_posts.create!(post: @post)

    assert @post.emailed?
  end

  test "emailed? returns false when digest exists but not yet delivered" do
    digest = PostDigest.create!(blog: @blog, kind: :individual)
    digest.digest_posts.create!(post: @post)

    assert_not @post.emailed?
  end

  test "emailed scope returns posts with delivered digests" do
    emailed_post = @blog.posts.create!(title: "Emailed", content: "Content")
    not_emailed_post = @blog.posts.create!(title: "Not emailed", content: "Content")

    digest = PostDigest.create!(blog: @blog, kind: :individual, delivered_at: Time.current)
    digest.digest_posts.create!(post: emailed_post)

    assert_includes Post.emailed, emailed_post
    assert_not_includes Post.emailed, not_emailed_post
  end

  test "not_emailed scope returns posts without delivered digests" do
    emailed_post = @blog.posts.create!(title: "Emailed", content: "Content")
    not_emailed_post = @blog.posts.create!(title: "Not emailed", content: "Content")

    digest = PostDigest.create!(blog: @blog, kind: :individual, delivered_at: Time.current)
    digest.digest_posts.create!(post: emailed_post)

    assert_not_includes Post.not_emailed, emailed_post
    assert_includes Post.not_emailed, not_emailed_post
  end

  test "not_emailed scope includes posts with undelivered digests" do
    post = @blog.posts.create!(title: "Pending", content: "Content")
    digest = PostDigest.create!(blog: @blog, kind: :individual, delivered_at: nil)
    digest.digest_posts.create!(post: post)

    assert_includes Post.not_emailed, post
  end

  test "individually_sent? returns false when post has not been sent" do
    assert_not @post.individually_sent?
  end

  test "individually_sent? returns true when post has been sent" do
    digest = PostDigest.create!(blog: @blog, kind: :individual, delivered_at: Time.current)
    digest.digest_posts.create!(post: @post)

    assert @post.individually_sent?
  end

  test "individually_sent? returns true even before delivery completes" do
    digest = PostDigest.create!(blog: @blog, kind: :individual)
    digest.digest_posts.create!(post: @post)

    assert_nil digest.delivered_at
    assert @post.individually_sent?
  end

  test "individually_sendable? returns true for eligible posts" do
    assert @post.individually_sendable?
  end

  test "individually_sendable? returns false for pages" do
    page = @blog.posts.create!(title: "Test Page", content: "Page content", is_page: true)
    assert_not page.individually_sendable?
  end

  test "individually_sendable? returns false for drafts" do
    draft = @blog.posts.create!(title: "Draft", content: "Draft content", status: :draft)
    assert_not draft.individually_sendable?
  end

  test "individually_sendable? returns false for hidden posts" do
    @post.update!(hidden: true)
    assert_not @post.individually_sendable?
  end

  test "individually_sendable? returns false if already sent" do
    digest = PostDigest.create!(blog: @blog, kind: :individual, delivered_at: Time.current)
    digest.digest_posts.create!(post: @post)

    assert_not @post.individually_sendable?
  end

  test "individually_sendable? returns false if email subscriptions disabled" do
    @blog.update!(email_subscriptions_enabled: false)
    assert_not @post.individually_sendable?
  end

  test "individually_sendable? returns false if no confirmed subscribers" do
    @blog.email_subscribers.update_all(confirmed_at: nil)
    assert_not @post.individually_sendable?
  end

  test "send_to_subscribers! creates digest and enqueues delivery" do
    assert_difference "PostDigest.count" do
      assert_enqueued_jobs 1, only: PostDigest::DeliveryJob do
        @post.send_to_subscribers!
      end
    end

    digest = PostDigest.last
    assert digest.individual?
    assert_equal @post, digest.posts.first
  end
end
