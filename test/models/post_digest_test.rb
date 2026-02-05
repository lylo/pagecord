require "test_helper"

class PostDigestTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @blog = blogs(:joel)
  end

  test "should not create digest if no new posts since last digest" do
    assert_nil PostDigest.generate_for(@blog)
  end

  test "should create new digest with posts since last digest" do
    new_post = create_new_post

    digest = PostDigest.generate_for(@blog)

    assert_not_nil digest
    assert_equal 1, digest.posts.count
    assert_includes digest.posts, new_post
  end

  test "should not include back-dated posts" do
    post = create_new_post(published_at: 2.weeks.ago)

    assert post.published?
    assert_nil PostDigest.generate_for(@blog)
  end

  test "should not include draft posts" do
    post = create_new_post(status: :draft)

    assert post.draft?
    assert_nil PostDigest.generate_for(@blog)
  end

  test "should not create digest if email_subscriptions_enabled is false" do
    @blog.update!(email_subscriptions_enabled: false)

    assert_nil PostDigest.generate_for(@blog)
  end

  test "should not create digest if user is not subscribed" do
    user = users(:vivian)

    assert_nil PostDigest.generate_for(user.blog)
  end

  test "should enqueue batch job for confirmed email subscribers" do
    create_new_post

    @blog.email_subscribers.create!(email: "newsub@example.com", confirmed_at: Time.current)
    assert_equal 2, @blog.email_subscribers.confirmed.count

    digest = PostDigest.generate_for(@blog)

    assert_enqueued_jobs 1, only: PostDigest::DeliveryJob do
      digest.deliver
    end

    refute digest.delivered_at?, "delivered_at should only be set after job completes"
  end

  test "should not enqueue job if already delivered" do
    create_new_post

    digest = PostDigest.generate_for(@blog)
    digest.update!(delivered_at: Time.current)

    assert_no_enqueued_jobs only: PostDigest::DeliveryJob do
      digest.deliver
    end
  end

  test "should not include hidden posts" do
    hidden_post = create_new_post(hidden: true)

    assert hidden_post.hidden?
    assert_nil PostDigest.generate_for(@blog)
  end

  test "masked_id should generate consistent masked ID" do
    digest = post_digests(:one)

    masked_id1 = digest.masked_id
    masked_id2 = digest.masked_id

    assert_equal masked_id1, masked_id2
    assert_not_equal digest.id.to_s, masked_id1
  end

  test "find_by_masked_id should find digest by masked ID" do
    digest = post_digests(:one)
    masked_id = digest.masked_id

    found_digest = PostDigest.find_by_masked_id(masked_id)

    assert_equal digest, found_digest
  end

  test "find_by_masked_id should return nil for invalid masked ID" do
    assert_nil PostDigest.find_by_masked_id("invalid")
    assert_nil PostDigest.find_by_masked_id("")
    assert_nil PostDigest.find_by_masked_id(nil)
  end

  test "subject should return localized digest subject" do
    digest = post_digests(:one)

    expected_subject = I18n.with_locale(digest.blog.locale) do
      I18n.t(
        "email_subscribers.mailers.weekly_digest.subject",
        blog_name: digest.blog.display_name,
        date: I18n.l(digest.created_at.to_date, format: :post_date)
      )
    end

    assert_equal expected_subject, digest.subject
  end

  test "send_individual creates an individual digest with one post" do
    post = create_new_post

    digest = PostDigest.send_individual(post)

    assert_not_nil digest
    assert digest.individual?
    assert_equal 1, digest.posts.count
    assert_includes digest.posts, post
  end

  test "send_individual returns nil if post already individually sent" do
    post = create_new_post
    digest = PostDigest.create!(blog: @blog, kind: :individual, delivered_at: Time.current)
    digest.digest_posts.create!(post: post)

    assert_nil PostDigest.send_individual(post)
  end

  test "generate_for returns nil if blog is in individual mode" do
    @blog.update!(email_delivery_mode: :individual)
    create_new_post

    assert_nil PostDigest.generate_for(@blog)
  end

  test "generate_for excludes posts with exclude_from_digest true" do
    create_new_post(exclude_from_digest: true)

    assert_nil PostDigest.generate_for(@blog)
  end

  test "generate_for excludes posts already in an individual digest" do
    post = create_new_post
    digest = PostDigest.create!(blog: @blog, kind: :individual)
    digest.digest_posts.create!(post: post)

    assert_nil PostDigest.generate_for(@blog)
  end

  test "subject returns post title for individual kind" do
    post = create_new_post(title: "My Great Post")
    digest = PostDigest.create!(blog: @blog, kind: :individual)
    digest.digest_posts.create!(post: post)

    assert_equal "My Great Post", digest.subject
  end

  test "subject returns fallback for individual kind without title" do
    post = create_new_post(title: nil)
    digest = PostDigest.create!(blog: @blog, kind: :individual)
    digest.digest_posts.create!(post: post)

    expected = I18n.t(
      "email_subscribers.mailers.individual.default_subject",
      blog_name: @blog.display_name,
      date: I18n.l(digest.created_at.to_date, format: :post_date)
    )

    assert_equal expected, digest.subject
  end

  private

    def create_new_post(options = {})
      @blog.posts.create!({ title: "New Post", content: "New post content" }.merge(options))
    end
end
