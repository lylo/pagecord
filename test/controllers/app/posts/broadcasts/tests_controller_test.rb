require "test_helper"

class App::Posts::Broadcasts::TestsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:joel)
    login_as @user
    @blog = @user.blog
    @blog.update!(email_subscriptions_enabled: true, email_delivery_mode: :individual)
    @post = @blog.posts.visible.posts.first
  end

  test "test sends test email to current user" do
    assert_enqueued_emails 1 do
      post app_post_broadcast_test_path(@post)
    end

    assert_redirected_to edit_app_post_path(@post)
    assert_equal "Test email sent to #{@user.email}.", flash[:notice]
  end

  test "test rejects if post already sent" do
    digest = PostDigest.create!(blog: @blog, kind: :individual, delivered_at: Time.current)
    digest.digest_posts.create!(post: @post)

    assert_no_enqueued_emails do
      post app_post_broadcast_test_path(@post)
    end

    assert_redirected_to edit_app_post_path(@post)
    assert_equal "Cannot send a test for this post.", flash[:alert]
  end

  test "test rejects draft posts" do
    draft = posts(:joel_draft)

    assert_no_enqueued_emails do
      post app_post_broadcast_test_path(draft)
    end

    assert_redirected_to edit_app_post_path(draft)
    assert_equal "Cannot send a test for this post.", flash[:alert]
  end

  test "test rejects if blog not in individual mode" do
    @blog.update!(email_delivery_mode: :digest)

    assert_no_enqueued_emails do
      post app_post_broadcast_test_path(@post)
    end

    assert_redirected_to edit_app_post_path(@post)
    assert_equal "Cannot send a test for this post.", flash[:alert]
  end
end
