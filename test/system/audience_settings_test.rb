require "application_system_test_case"

class AudienceSettingsTest < ApplicationSystemTestCase
  setup do
    @user = users(:joel)
    @blog = @user.blog
    @blog.update!(email_subscriptions_enabled: true)

    access_request = @user.access_requests.create!
    visit verify_access_request_path(token: access_request.token_digest)
    assert_current_path app_posts_path
  end

  test "toggling email subscriptions disables and greys out the dependent rows" do
    visit app_settings_audience_index_path

    # Enabled to start: the dependent controls are interactive and not greyed
    assert_selector "#blog_show_subscription_in_header:enabled"
    assert_no_selector "[data-subscription-settings-target='dependent'].opacity-50"

    uncheck "Email subscriptions enabled"

    # Dependent checkboxes become disabled and their rows grey out
    assert_selector "#blog_show_subscription_in_header:disabled"
    assert_selector "#blog_show_subscription_in_footer:disabled"
    assert_selector "[data-subscription-settings-target='dependent'].opacity-50"

    check "Email subscriptions enabled"

    assert_selector "#blog_show_subscription_in_header:enabled"
    assert_no_selector "[data-subscription-settings-target='dependent'].opacity-50"
  end
end
