require "test_helper"

class App::Settings::NavigationItemsControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @blog = blogs(:joel)
    @user = users(:joel)
    login_as @user
  end

  test "index shows all navigation items" do
    get app_settings_navigation_items_path
    assert_response :success
    assert_select "h2", "Navigation"
  end

  test "index shows pages dropdown without home page" do
    home_page = posts(:about)
    @blog.update(home_page: home_page)

    get app_settings_navigation_items_path
    assert_response :success

    # Home page should not be in dropdown
    assert_select "select[name='navigation_item[post_id]'] option[value='#{home_page.id}']", count: 0
  end

  test "create page navigation item" do
    page = posts(:draft_page)

    assert_difference -> { PageNavigationItem.count }, 1 do
      post app_settings_navigation_items_path, params: {
        nav_type: "page",
        navigation_item: { post_id: page.id }
      }
    end

    assert_redirected_to app_settings_navigation_items_path
    assert_equal "Navigation item added", flash[:notice]

    item = PageNavigationItem.last
    assert_equal @blog, item.blog
    assert_equal page, item.post
    assert_equal 5, item.position # After existing items
  end

  test "create custom navigation item" do
    assert_difference -> { CustomNavigationItem.count }, 1 do
      post app_settings_navigation_items_path, params: {
        nav_type: "custom",
        navigation_item: { label: "Archive", url: "/archive" }
      }
    end

    assert_redirected_to app_settings_navigation_items_path

    item = CustomNavigationItem.last
    assert_equal "Archive", item.label
    assert_equal "/archive", item.url
  end

  test "create social navigation item" do
    assert_difference -> { SocialNavigationItem.count }, 1 do
      post app_settings_navigation_items_path, params: {
        nav_type: "social",
        navigation_item: { platform: "GitHub", url: "https://github.com/user" }
      }
    end

    assert_redirected_to app_settings_navigation_items_path

    item = SocialNavigationItem.last
    assert_equal "GitHub", item.platform
    assert_equal "https://github.com/user", item.url
    assert_equal "GitHub", item.label
  end

  test "create with validation errors re-renders form" do
    assert_no_difference -> { CustomNavigationItem.count } do
      post app_settings_navigation_items_path, params: {
        nav_type: "custom",
        navigation_item: { label: "Test" } # Missing URL
      }
    end

    assert_response :unprocessable_entity
    assert_select ".text-red-500", /can't be blank/
  end

  test "update position via drag and drop" do
    item = navigation_items(:joel_about)
    assert_equal 1, item.position

    patch app_settings_navigation_item_path(item), params: {
      navigation_item: { position: 3 }
    }

    assert_response :success
    assert_equal 3, item.reload.position

    # Other items should shift
    assert_equal 1, navigation_items(:joel_custom).reload.position
    assert_equal 2, navigation_items(:joel_social_bluesky).reload.position
  end

  test "destroy removes navigation item" do
    item = navigation_items(:joel_custom)

    assert_difference -> { NavigationItem.count }, -1 do
      delete app_settings_navigation_item_path(item)
    end

    assert_redirected_to app_settings_navigation_items_path
    assert_equal "Navigation item removed", flash[:notice]
  end
end
