require "application_system_test_case"

class BlogSettingsTest < ApplicationSystemTestCase
  setup do
    @user = users(:joel)

    access_request = @user.access_requests.create!
    visit access_request_verification_path(token: access_request.token_digest)
    assert_current_path app_posts_path
  end

  test "the eye button reveals and re-masks the blog password" do
    visit app_settings_blog_path
    check "Password protect this blog"

    assert_selector "#blog_password[type='password']"

    find("button[aria-label='Show password']").click

    assert_selector "#blog_password[type='text']"

    find("button[aria-label='Hide password']").click

    assert_selector "#blog_password[type='password']"
  end
end
