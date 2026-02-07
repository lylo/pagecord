require "test_helper"

class Blogs::ContactMessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)
    @user = @blog.user
    host! "#{@blog.subdomain}.lvh.me"
  end

  test "should create contact message for premium user" do
    assert @user.has_premium_access?

    assert_difference "Blog::ContactMessage.count", 1 do
      post contact_messages_url,
        params: {
          contact_message: { name: "Test User", email: "test@example.com", message: "Hello!" },
          rendered_at: 10.seconds.ago.to_i
        }
    end

    assert_redirected_to blog_posts_path
    assert_equal I18n.t("email_form.success_message"), flash[:notice]
    assert_enqueued_jobs 1, only: SendContactMessageJob
  end

  test "should return 422 for non-premium user" do
    @user.subscription.destroy
    @user.update!(created_at: 30.days.ago)

    assert_not @user.reload.has_premium_access?

    assert_no_difference "Blog::ContactMessage.count" do
      post contact_messages_url,
        params: {
          contact_message: { name: "Test User", email: "test@example.com", message: "Hello!" },
          rendered_at: 10.seconds.ago.to_i
        }
    end

    assert_response :unprocessable_entity
  end

  test "should block honeypot submissions" do
    assert_no_difference "Blog::ContactMessage.count" do
      post contact_messages_url,
        params: {
          contact_message: { name: "Test User", email: "test@example.com", message: "Hello!" },
          email_confirmation: "spam@example.com",
          rendered_at: 10.seconds.ago.to_i
        }
    end

    assert_response :forbidden
  end

  test "should block fast form submissions" do
    assert_no_difference "Blog::ContactMessage.count" do
      post contact_messages_url,
        params: {
          contact_message: { name: "Test User", email: "test@example.com", message: "Hello!" },
          rendered_at: Time.current.to_i
        }
    end

    assert_response :forbidden
  end

  test "should redirect with error for invalid message" do
    assert_no_difference "Blog::ContactMessage.count" do
      post contact_messages_url,
        params: {
          contact_message: { name: "", email: "invalid", message: "" },
          rendered_at: 10.seconds.ago.to_i
        }
    end

    assert_redirected_to blog_posts_path
    assert_equal I18n.t("email_form.error_message"), flash[:alert]
  end
end
