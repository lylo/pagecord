require "test_helper"

class Blogs::EmailSubscribersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)
  end

  test "should add new email subscriber" do
    assert_difference("EmailSubscriber.count", 1) do
      post email_subscribers_url(name: @blog.name), params: { blog_name: @blog.name, email_subscriber: { email: "test@example.com" } }, as: :turbo_stream
    end

    assert_response :success
    assert_includes @response.body, "Thanks for subscribing"
  end

  test "should not add existing email subscriber" do
    assert_no_difference("EmailSubscriber.count") do
      post email_subscribers_url(name: @blog.name), params: { blog_name: @blog.name, email_subscriber: { email: @blog.email_subscribers.first.email } }, as: :turbo_stream
    end

    assert_response :success
  end

  test "should not add email subscriber if user is not subscribed" do
    blog = blogs(:vivian)
    assert_not blog.user.subscribed?

    assert_no_difference("EmailSubscriber.count") do
      post email_subscribers_url(name: blog.name), params: { blog_name: blog.name, email_subscriber: { email: "test@example.com" } }, as: :turbo_stream
    end
  end

  test "should not add email subscriber if honeypot field is completed" do
    assert_no_difference("EmailSubscriber.count") do
      post email_subscribers_url(name: @blog.name), params: {
          blog_name: @blog.name,
          email_subscriber: {
            email: "test@example.com"
          },
          email_confirmation: "test@example.com" },
        as: :turbo_stream
    end
  end
end
