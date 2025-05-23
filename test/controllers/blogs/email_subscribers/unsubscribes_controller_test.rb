require "test_helper"

class Blogs::EmailSubscribers::UnsubscribesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)
  end

  test "should unsubscribe email subscription" do
    assert_difference -> { @blog.email_subscribers.count }, -1 do
      post email_subscriber_unsubscribe_path(name: @blog.name, token: @blog.email_subscribers.first.token)
    end

    assert_response :success
    assert_includes @response.body, "You're now unsubscribed"
  end

  test "should fail gracefully with invalid token" do
    post email_subscriber_unsubscribe_path(name: @blog.name, token: "unknown")
    assert_redirected_to root_path
    assert_equal "No email subscription found", flash[:alert]
  end
end
