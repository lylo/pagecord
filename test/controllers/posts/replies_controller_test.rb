require "test_helper"

class Posts::RepliesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @post = posts(:one)
    @reply_params = {
      name: "Test User",
      email: "test@example.com",
      subject: "Test Subject",
      message: "This is a test message."
    }
  end

  test "should get new reply form" do
    get new_post_reply_path(@post)
    assert_response :success
    assert_select "form[action=?]", post_replies_path(@post)
  end

  test "should create reply and send email" do
    assert_difference("Post::Reply.count", 1) do
      post post_replies_path(@post), params: { reply: @reply_params }
    end

    assert_enqueued_emails 1
    assert_redirected_to post_with_title_path(@post.blog.name, @post.url_title, @post.token)
    follow_redirect!
    assert_equal "Reply sent successfully!", flash[:notice]
  end

  test "should not create reply with invalid data" do
    invalid_params = @reply_params.merge(email: "")
    assert_no_difference("Post::Reply.count") do
      post post_replies_path(@post), params: { reply: invalid_params }
    end

    assert_response :unprocessable_entity
    assert_select "span", text: /Email can't be blank/
  end
end
