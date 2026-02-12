require "test_helper"

class Blogs::EmailSubscribersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)
    host! "#{@blog.subdomain}.#{Rails.application.config.x.domain}"
  end

  test "should add new email subscriber" do
    assert_difference("EmailSubscriber.count", 1) do
      post email_subscribers_url(subdomain: @blog.subdomain), params: { blog_subdomain: @blog.subdomain, email_subscriber: { email: "test@example.com" }, rendered_at: signed_rendered_at }, as: :turbo_stream
    end

    assert_response :success
    assert_includes @response.body, "Thanks for subscribing"
  end

  test "should not add existing email subscriber" do
    assert_no_difference("EmailSubscriber.count") do
      post email_subscribers_url(subdomain: @blog.subdomain), params: { blog_subdomain: @blog.subdomain, email_subscriber: { email: @blog.email_subscribers.first.email }, rendered_at: signed_rendered_at }, as: :turbo_stream
    end

    assert_response :success
  end

  test "should not add email subscriber if form is completed too quickly" do
    assert_no_difference("EmailSubscriber.count") do
      post email_subscribers_url(subdomain: @blog.subdomain), params: { blog_subdomain: @blog.subdomain, email_subscriber: { email: "test@example.com" }, rendered_at: signed_rendered_at(1.second.ago) }, as: :turbo_stream
    end
  end

  test "should not add email subscriber if user is not subscribed" do
    host! "vivian.example.com"
    blog = blogs(:vivian)
    assert_not blog.user.subscribed?

    assert_no_difference("EmailSubscriber.count") do
      post email_subscribers_url(subdomain: blog.subdomain), params: { blog_subdomain: blog.subdomain, email_subscriber: { email: "test@example.com" }, rendered_at: signed_rendered_at }, as: :turbo_stream
    end
  end

  test "should not add email subscriber if honeypot field is completed" do
    assert_no_difference("EmailSubscriber.count") do
      post email_subscribers_url(subdomain: @blog.subdomain), params: {
          blog_subdomain: @blog.subdomain,
          email_subscriber: {
            email: "test@example.com"
          },
          email_confirmation: "test@example.com" },
        as: :turbo_stream
    end
  end

  test "should handle HTML request and redirect to blog home" do
    assert_difference("EmailSubscriber.count", 1) do
      post email_subscribers_url(subdomain: @blog.subdomain), params: {
        blog_subdomain: @blog.subdomain,
        email_subscriber: { email: "test@example.com" },
        rendered_at: signed_rendered_at
      }
    end

    assert_redirected_to blog_posts_path
    assert_equal "Thanks for subscribing. Unless you're already subscribed, a confirmation email is on its way to test@example.com", flash[:notice]
  end
end
