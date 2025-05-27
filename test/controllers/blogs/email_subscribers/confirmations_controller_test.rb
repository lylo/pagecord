require "test_helper"

class Blogs::EmailSubscribers::ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  test "should confirm email subscription" do
    @blog = blogs(:joel)
    host! "#{@blog.name}.#{Rails.application.config.x.domain}"

    subscriber = @blog.email_subscribers.create!(email: "new@test.com")
    assert subscriber.unconfirmed?

    get email_subscriber_confirmation_path(token: subscriber.token)

    assert_response :success
    assert subscriber.reload.confirmed?
    assert_includes @response.body, "Your subscription to"
  end
end
