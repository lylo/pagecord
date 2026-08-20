require "test_helper"

class Blogs::EmailSubscribers::ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  test "should confirm email subscription" do
    @blog = blogs(:joel)
    host! "#{@blog.subdomain}.#{Rails.application.config.x.domain}"

    subscriber = @blog.email_subscribers.create!(email: "new@test.com")
    assert subscriber.unconfirmed?

    get email_subscriber_confirmation_path(token: subscriber.token)

    assert_response :success
    assert subscriber.reload.confirmed?
    assert_includes @response.body, "Your subscription to"
  end

  test "should confirm email subscription in the blog's locale" do
    @blog = blogs(:joel)
    @blog.update!(locale: "fr")
    host! "#{@blog.subdomain}.#{Rails.application.config.x.domain}"

    subscriber = @blog.email_subscribers.create!(email: "new@test.com")

    get email_subscriber_confirmation_path(token: subscriber.token)

    assert_response :success
    assert_includes @response.body, "Ton abonnement à"
  end

  test "should confirm email subscription to a password protected blog without the password" do
    @blog = blogs(:joel)
    @blog.update!(password: "letmein")
    host! "#{@blog.subdomain}.#{Rails.application.config.x.domain}"

    subscriber = @blog.email_subscribers.create!(email: "new@test.com")

    get email_subscriber_confirmation_path(token: subscriber.token)

    assert_response :success
    assert subscriber.reload.confirmed?
    assert_includes @response.body, "Your subscription to"
  end
end
