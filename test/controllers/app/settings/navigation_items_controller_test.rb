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
    assert_select "h3", "Navigation"
    assert_select "button[aria-label='Navigation help']"
    assert_select "[data-dialog-shortcut-value='?']"
    assert_includes response.body, "/posts"
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
        navigation_item: { platform: "Pixelfed", url: "https://pixelfed.social/user" }
      }
    end

    assert_redirected_to app_settings_navigation_items_path

    item = SocialNavigationItem.last
    assert_equal "Pixelfed", item.platform
    assert_equal "https://pixelfed.social/user", item.url
    assert_equal "Pixelfed", item.label
  end

  test "create search navigation item" do
    assert_difference -> { SearchNavigationItem.count }, 1 do
      post app_settings_navigation_items_path, params: {
        nav_type: "search",
        navigation_item: { label: "Search" }
      }
    end

    assert_redirected_to app_settings_navigation_items_path

    item = SearchNavigationItem.last
    assert_equal @blog, item.blog
    assert_equal "Search", item.label
    assert_equal "/search", item.link_url
  end

  test "only one search navigation item allowed per blog" do
    @blog.navigation_items.create!(type: "SearchNavigationItem")

    assert_no_difference -> { SearchNavigationItem.count } do
      post app_settings_navigation_items_path, params: {
        nav_type: "search",
        navigation_item: { label: "Search" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "search radio hidden once a search item exists" do
    get app_settings_navigation_items_path
    assert_select "input[name='nav_type'][value='search']", count: 1

    @blog.navigation_items.create!(type: "SearchNavigationItem")

    get app_settings_navigation_items_path
    assert_select "input[name='nav_type'][value='search']", count: 0
  end

  test "create with validation errors re-renders form" do
    assert_no_difference -> { CustomNavigationItem.count } do
      post app_settings_navigation_items_path, params: {
        nav_type: "custom",
        navigation_item: { label: "Test" } # Missing URL
      }
    end

    assert_response :unprocessable_entity
    assert_select ".field-error", /can't be blank/
  end

  test "create social navigation with validation errors uses navigation_item params" do
    # This test ensures the form uses scope: :navigation_item
    # Without it, validation errors would cause params[:social_navigation_item]
    # which would raise ParameterMissing exception
    assert_no_difference -> { SocialNavigationItem.count } do
      post app_settings_navigation_items_path, params: {
        nav_type: "social",
        navigation_item: { platform: "Email" } # Missing URL
      }
    end

    assert_response :unprocessable_entity
    assert_select ".field-error", /can't be blank/
  end

  test "create page navigation with validation errors uses navigation_item params" do
    assert_no_difference -> { PageNavigationItem.count } do
      post app_settings_navigation_items_path, params: {
        nav_type: "page",
        navigation_item: { post_id: nil } # Missing post_id
      }
    end

    assert_response :unprocessable_entity
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
