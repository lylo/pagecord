require "test_helper"

class Blogs::EmailSubscribers::UnsubscribesControllerTest < ActionDispatch::IntegrationTest
  test "should unsubscribe email subscription" do
    blog = blogs(:joel)
    subscriber = blog.email_subscribers.first

    assert_difference -> { blog.email_subscribers.count }, -1 do
      post email_subscriber_unsubscribe_path(name: blog.name, token: subscriber.token)
    end

    assert_response :success
    assert_includes @response.body, "You're now unsubscribed"
  end
end
