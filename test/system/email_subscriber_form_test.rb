require "application_system_test_case"

class EmailSubscriberFormTest < ApplicationSystemTestCase
  test "a visitor subscribes from a blog page" do
    blog = blogs(:joel)
    blog.update!(email_subscriptions_enabled: true, show_subscription_in_header: true)
    Blogs::EmailSubscribersController.any_instance.stubs(:minimum_form_completion_time).returns(0)

    use_subdomain(blog.subdomain)
    visit blog_posts_path

    fill_in "email_subscriber[email]", with: "gran@example.com"
    click_button "Subscribe"

    assert page.has_content?("Thanks for subscribing", wait: 5)
    assert blog.email_subscribers.exists?(email: "gran@example.com")
  end
end
