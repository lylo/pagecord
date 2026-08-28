require "application_system_test_case"

class NavigationItemsTest < ApplicationSystemTestCase
  # Everything else on this page is plain form CRUD, covered by the controller
  # and model tests. The platform-to-URL prepopulation is Stimulus.
  test "social platform selection prepopulates the URL" do
    user = users(:joel)
    access_request = user.access_requests.create!
    visit access_request_verification_path(token: access_request.token_digest)

    visit app_settings_navigation_items_path

    choose "Social link"
    select "RSS", from: "Platform"

    assert_field "URL", with: %r{/feed\.xml}

    click_on "Add to Navigation"

    # Wait for the redirect to land first. Reading the list while Turbo is
    # still swapping the body reads a node that is already gone.
    assert_text "Navigation item added"
    assert_selector "[data-controller='sortable']", text: "RSS"

    assert_instance_of SocialNavigationItem, user.blog.navigation_items.find_by(platform: "RSS")
  end
end
