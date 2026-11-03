require "test_helper"

class BlogFormNonceTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)
    host! "#{@blog.subdomain}.#{Rails.application.config.x.domain}"
  end

  test "the subscribe form fetches the nonce when first used" do
    @blog.update!(email_subscriptions_enabled: true, show_subscription_in_header: true)

    get blog_posts_path

    assert_select "body[data-controller~=form-nonce]", count: 0
    assert_select "form[action=?][data-controller~=form-nonce][data-action~=?][data-form-nonce-url-value=?]",
      email_subscribers_path, "focusin->form-nonce#prepare", blog_form_nonce_path
  end

  test "a subscription without the nonce is refused and asked to reload" do
    assert_no_difference "EmailSubscriber.count" do
      subscribe
    end

    assert_includes response.body, "reload the page"
  end

  test "a subscription after the page fetched its nonce is accepted" do
    post blog_form_nonce_path

    assert_difference "EmailSubscriber.count", 1 do
      subscribe
    end
  end

  test "a forged nonce is refused" do
    post blog_form_nonce_path
    cookies["form_nonce"] = "forged"

    assert_no_difference "EmailSubscriber.count" do
      subscribe
    end
  end

  test "a contact message without the nonce is refused and asked to reload" do
    assert_no_difference "Blog::ContactMessage.count" do
      post contact_messages_path,
        params: { contact_message: { name: "Test", email: "test@example.com", message: "Hello" }, rendered_at: signed_rendered_at(10.seconds.ago) },
        as: :turbo_stream
    end

    assert_includes response.body, "reload the page"
  end

  test "a comment without the nonce is refused on the thread" do
    post = posts(:one)

    assert_no_difference "Post::Comment.count" do
      post post_comments_path(post),
        params: { comment: { name: "Test", message: "Hello" }, form_token: post.signed_id(purpose: :comment_form), rendered_at: signed_rendered_at }
    end

    assert_response :unprocessable_entity
    assert_select "p.comment-notice"
  end

  private

    def subscribe
      post email_subscribers_path,
        params: { email_subscriber: { email: "test@example.com" }, rendered_at: signed_rendered_at },
        as: :turbo_stream
    end
end
