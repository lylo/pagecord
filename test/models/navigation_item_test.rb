require "test_helper"

class NavigationItemTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
    @page = posts(:about)
  end

  test "ordered scope orders by position" do
    items = @blog.navigation_items.ordered
    assert_equal [ 1, 2, 3, 4 ], items.map(&:position)
  end

  test "reorder moves item down in list" do
    item1 = navigation_items(:joel_about)
    item2 = navigation_items(:joel_custom)
    item3 = navigation_items(:joel_social_bluesky)

    item1.reorder(3)

    assert_equal 3, item1.reload.position
    assert_equal 1, item2.reload.position
    assert_equal 2, item3.reload.position
  end

  test "reorder moves item up in list" do
    item1 = navigation_items(:joel_about)
    item2 = navigation_items(:joel_custom)
    item3 = navigation_items(:joel_social_bluesky)

    item3.reorder(1)

    assert_equal 2, item1.reload.position
    assert_equal 3, item2.reload.position
    assert_equal 1, item3.reload.position
  end

  test "reorder to same position does nothing" do
    item1 = navigation_items(:joel_about)
    item2 = navigation_items(:joel_custom)
    item3 = navigation_items(:joel_social_bluesky)

    item2.reorder(2)

    assert_equal 1, item1.reload.position
    assert_equal 2, item2.reload.position
    assert_equal 3, item3.reload.position
  end

  test "reorder moves item to middle of list" do
    item1 = navigation_items(:joel_about)
    item2 = navigation_items(:joel_custom)

    item1.reorder(2)

    assert_equal 2, item1.reload.position
    assert_equal 1, item2.reload.position
  end

  test "destroying item reorders remaining items" do
    item1 = navigation_items(:joel_about)
    item2 = navigation_items(:joel_custom)
    item3 = navigation_items(:joel_social_bluesky)
    item4 = navigation_items(:joel_hidden)

    assert_equal 1, item1.position
    assert_equal 2, item2.position
    assert_equal 3, item3.position
    assert_equal 4, item4.position

    item2.destroy

    assert_equal 1, item1.reload.position
    assert_equal 2, item3.reload.position
    assert_equal 3, item4.reload.position
  end
end

class PageNavigationItemTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
    @page = posts(:about)
    @nav_item = navigation_items(:joel_about)
  end

  test "valid with post" do
    item = PageNavigationItem.new(blog: @blog, post: @page)
    assert item.valid?
  end

  test "invalid without post" do
    item = PageNavigationItem.new(blog: @blog)
    assert_not item.valid?
    assert_includes item.errors[:post], "can't be blank"
  end

  test "label returns post display_title" do
    assert_equal @page.display_title, @nav_item.label
  end

  test "link_url returns post path" do
    assert_equal Rails.application.routes.url_helpers.blog_post_path(@page), @nav_item.link_url
  end
end

class CustomNavigationItemTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
    @nav_item = navigation_items(:joel_custom)
  end

  test "valid with label and url" do
    item = CustomNavigationItem.new(blog: @blog, label: "Archive", url: "/archive")
    assert item.valid?
  end

  test "invalid without label" do
    item = CustomNavigationItem.new(blog: @blog, url: "/posts")
    assert_not item.valid?
    assert_includes item.errors[:label], "can't be blank"
  end

  test "invalid without url" do
    item = CustomNavigationItem.new(blog: @blog, label: "Test")
    assert_not item.valid?
    assert_includes item.errors[:url], "can't be blank"
  end

  test "link_url returns url" do
    assert_equal "/posts", @nav_item.link_url
  end
end

class SocialNavigationItemTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
    @nav_item = navigation_items(:joel_social_bluesky)
  end

  test "valid with platform and url" do
    item = SocialNavigationItem.new(blog: @blog, platform: "GitHub", url: "https://github.com/user")
    assert item.valid?
  end

  test "invalid without platform" do
    item = SocialNavigationItem.new(blog: @blog, url: "https://example.com")
    assert_not item.valid?
    assert_includes item.errors[:platform], "can't be blank"
  end

  test "invalid without url" do
    item = SocialNavigationItem.new(blog: @blog, platform: "GitHub")
    assert_not item.valid?
    assert_includes item.errors[:url], "can't be blank"
  end

  test "invalid with non-platform value" do
    item = SocialNavigationItem.new(blog: @blog, platform: "FakeBook", url: "https://example.com")
    assert_not item.valid?
    assert_includes item.errors[:platform], "is not included in the list"
  end

  test "label auto-sets from platform" do
    item = SocialNavigationItem.new(blog: @blog, platform: "GitHub", url: "https://github.com/user")
    item.valid?
    assert_equal "GitHub", item.label
  end

  test "link_url returns url" do
    assert_equal "https://bsky.app/profile/joel.example.com", @nav_item.link_url
  end

  test "email? returns true for Email platform" do
    item = SocialNavigationItem.new(platform: "Email")
    assert item.email?
  end

  test "email? returns false for other platforms" do
    assert_not @nav_item.email?
  end

  test "validates email format for Email platform" do
    item = SocialNavigationItem.new(blog: @blog, platform: "Email", url: "test@example.com")
    assert item.valid?

    item.url = "not-an-email"
    assert_not item.valid?
    assert_includes item.errors[:url], "must be a valid email address"
  end

  test "validates HTTP/HTTPS for non-Email platforms" do
    item = SocialNavigationItem.new(blog: @blog, platform: "GitHub", url: "https://github.com/user")
    assert item.valid?

    item.url = "ftp://example.com"
    assert_not item.valid?
    assert_includes item.errors[:url], "must be HTTP or HTTPS"
  end

  test "validates URL format" do
    item = SocialNavigationItem.new(blog: @blog, platform: "GitHub", url: "not a url")
    assert_not item.valid?
    assert_includes item.errors[:url], "is not a valid URL"
  end
end
