require "test_helper"

class App::Posts::BroadcastsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:joel)
    login_as @user
    @blog = @user.blog
    @blog.update!(email_subscriptions_enabled: true, email_delivery_mode: :individual)
    @post = @blog.posts.published.posts.first
  end

  test "create sends post to subscribers and redirects" do
    assert_difference "PostDigest.count" do
      assert_enqueued_jobs 1, only: PostDigest::DeliveryJob do
        post app_post_broadcast_path(@post)
      end
    end

    assert_redirected_to edit_app_post_path(@post)
    assert_equal "Sent to subscribers.", flash[:notice]
  end

  test "create rejects if blog not in individual mode" do
    @blog.update!(email_delivery_mode: :digest)

    assert_no_difference "PostDigest.count" do
      post app_post_broadcast_path(@post)
    end

    assert_redirected_to edit_app_post_path(@post)
    assert_equal "Cannot send this post to subscribers.", flash[:alert]
  end

  test "create rejects if post already sent" do
    digest = PostDigest.create!(blog: @blog, kind: :individual, delivered_at: Time.current)
    digest.digest_posts.create!(post: @post)

    assert_no_difference "PostDigest.count" do
      post app_post_broadcast_path(@post)
    end

    assert_redirected_to edit_app_post_path(@post)
    assert_equal "Cannot send this post to subscribers.", flash[:alert]
  end

  test "create rejects for draft posts" do
    draft = posts(:joel_draft)

    assert_no_difference "PostDigest.count" do
      post app_post_broadcast_path(draft)
    end

    assert_redirected_to edit_app_post_path(draft)
    assert_equal "Cannot send this post to subscribers.", flash[:alert]
  end

  test "create returns 404 for pages" do
    page = posts(:about) # about is joel's page
    # Pages are filtered out by blog.posts association, so they return 404
    post app_post_broadcast_path(page)
    assert_response :not_found
  end
end
