require "application_system_test_case"

class NavigationItemsTest < ApplicationSystemTestCase
  setup do
    @user = users(:joel)
    @blog = @user.blog

    access_request = @user.access_requests.create!
    visit verify_access_request_url(token: access_request.token_digest)

    assert_current_path app_posts_path
  end

  test "can add custom navigation item" do
    visit app_settings_navigation_items_path

    assert_difference -> { CustomNavigationItem.count }, 1 do
      choose "Custom link"
      fill_in "Label", with: "Archive"
      fill_in "URL", with: "/archive"

      click_on "Add to Navigation"
      sleep 1
    end

    item = @blog.navigation_items.find_by(label: "Archive", url: "/archive")
    assert_instance_of CustomNavigationItem, item
  end

  test "can add social navigation item with RSS prepopulation" do
    visit app_settings_navigation_items_path

    choose "Social link"
    select "RSS", from: "Platform"
    sleep 0.1

    url_field = find_field("URL")
    assert_match "/feed.xml", url_field.value

    assert_difference -> { SocialNavigationItem.count }, 1 do
      click_on "Add to Navigation"
      sleep 1
    end

    item = @blog.navigation_items.find_by(platform: "RSS")
    assert_instance_of SocialNavigationItem, item
  end

  test "can delete navigation item" do
    visit app_settings_navigation_items_path

    assert_difference -> { @blog.navigation_items.count }, -1 do
      accept_confirm do
        first("form[action*='navigation_items'] button[type='submit']").click
      end
      sleep 1
    end
  end
end
