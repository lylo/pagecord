require "application_system_test_case"

class NavigationItemsTest < ApplicationSystemTestCase
  # Everything else on this page is plain form CRUD, covered by the controller
  # and model tests. The platform-to-URL prepopulation is Stimulus.
  test "social platform selection prepopulates the URL" do
    user = users(:joel)
    access_request = user.access_requests.create!
    visit access_request_verification_path(token: access_request.token_digest)

    visit app_settings_navigation_items_path
    forms_before = user.blog.navigation_items.count + 1

    choose "Social link"
    select "RSS", from: "Platform"

    # A retrying matcher, not find_field().value: the Stimulus controller
    # replaces the field while prepopulating, so a held reference goes stale.
    assert_field "URL", with: %r{/feed\.xml}

    click_on "Add to Navigation"
    assert_selector "form[action*='navigation_items']", count: forms_before + 1

    assert_instance_of SocialNavigationItem, user.blog.navigation_items.find_by(platform: "RSS")
  end
end
