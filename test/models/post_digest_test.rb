require "test_helper"

class PostDigestTest < ActiveSupport::TestCase
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

  test "should create deliveries for each email subscriber" do
    create_new_post

    digest = PostDigest.generate_for(@blog)

    assert_difference "PostDigestDelivery.count", @blog.email_subscribers.count do
      digest.deliver
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

  private

    def create_new_post
      @blog.posts.create!(title: "New Post", content: "New post content")
    end
end
