require "test_helper"

class Posts::RepliesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
    host! "#{@post.blog.subdomain}.#{Rails.application.config.x.domain}"
  end

  test "should get new reply form" do
    get new_post_reply_path(@post)
    assert_response :success
    assert_select "form[action=?]", post_replies_path(@post)
  end

  test "should get new reply form for custom domain" do
    post = posts(:four)

    get new_post_reply_url(post, host: post.blog.custom_domain)

    assert_response :success
    assert_select "form[action=?]", post_replies_path(post)
  end

  test "should redirect to post if reply by email is disabled" do
    @post.blog.update(reply_by_email: false)
    get new_post_reply_path(@post)
    assert_redirected_to blog_post_path(@post.slug)
  end

  test "should create reply and send email" do
    assert_difference("Post::Reply.count", 1) do
      params = reply_params.merge(spam_prevention_params(@post))

      post post_replies_path(@post), params: params
    end

    assert_enqueued_jobs 1, only: SendPostReplyJob
    assert_redirected_to blog_post_path(@post.slug)
    follow_redirect!
    assert_equal "Reply sent successfully!", flash[:notice]
  end

  test "should not create reply with invalid data" do
    params = reply_params.merge({ reply: { email: "" } }).merge(spam_prevention_params(@post))

    assert_no_difference("Post::Reply.count") do
      post post_replies_path(@post), params: params
    end

    assert_response :unprocessable_entity
    assert_select "span", text: /Email can't be blank/
  end

  test "should not create reply if honeypot field is populated" do
    assert_no_difference("Post::Reply.count") do
      params = reply_params.merge(email_confirmation: "test@test.com")

      post post_replies_path(@post), params: params
    end

    assert_response :forbidden
  end

  private

    def reply_params
      {
        reply: {
          name: "Test User",
          email: "test@example.com",
          subject: "Test Subject",
          message: "This is a test message."
        }
      }
    end

    def spam_prevention_params(post)
      {
          form_token: encryptor.encrypt_and_sign({
            post_id: post.id
          }),
          rendered_at: signed_rendered_at(10.seconds.ago)
      }
    end

    def encryptor
      key = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base).generate_key("form-token", 32)
      ActiveSupport::MessageEncryptor.new(key)
    end
end
