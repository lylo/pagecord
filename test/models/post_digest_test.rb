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

  test "should create deliveries for confirmed email subscribers" do
    create_new_post

    @blog.email_subscribers.create!(email: "newsub@example.com", confirmed_at: Time.current)
    assert_equal 2, @blog.email_subscribers.confirmed.count

    digest = PostDigest.generate_for(@blog)

    assert_performed_jobs 2, only: SendPostDigestEmailJob do
      assert_difference "PostDigestDelivery.count", 2 do
        digest.deliver
      end
    end

    assert digest.delivered_at?
  end

  test "should only register deliveries once" do
    create_new_post

    digest = PostDigest.generate_for(@blog)
    digest.deliver

    assert_no_difference "PostDigestDelivery.count" do
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

  private

    def create_new_post(options = {})
      @blog.posts.create!({ title: "New Post", content: "New post content" }.merge(options))
    end
end
