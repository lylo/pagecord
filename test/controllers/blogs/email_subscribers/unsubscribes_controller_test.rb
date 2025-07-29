require "test_helper"

class Blogs::EmailSubscribers::UnsubscribesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)
    host! "#{@blog.subdomain}.#{Rails.application.config.x.domain}"
  end

  test "should unsubscribe email subscription" do
    assert_difference -> { @blog.email_subscribers.count }, -1 do
      post email_subscriber_unsubscribe_path(token: @blog.email_subscribers.first.token)
    end

    assert_response :success
    assert_includes @response.body, "You&#39;re now unsubscribed"
  end

  test "should fail gracefully with invalid token" do
    post email_subscriber_unsubscribe_path(token: "unknown")
    assert_redirected_to root_path
    assert_equal "No email subscription found", flash[:alert]
  end

  test "should unsubscribe via one click without CSRF token" do
    assert_difference -> { @blog.email_subscribers.count }, -1 do
      post email_subscriber_one_click_unsubscribe_path(token: @blog.email_subscribers.first.token)
    end

    assert_response :success
    assert_includes @response.body, "You're now unsubscribed"
  end

  test "should fail gracefully with invalid token for one click" do
    post email_subscriber_one_click_unsubscribe_path(token: "unknown")
    assert_redirected_to root_path
    assert_equal "No email subscription found", flash[:alert]
  end
end
