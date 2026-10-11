require "test_helper"

class NavigationItemTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
    @page = posts(:about)
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

  test "link_url returns post path with slug" do
    expected_path = Rails.application.routes.url_helpers.blog_post_path(@page.slug)
    assert_equal expected_path, @nav_item.link_url
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

  test "a pasted icon keeps only its shapes, in the theme colour" do
    item = CustomNavigationItem.new(blog: @blog, label: "Listening", url: "/listening", icon_svg: <<~SVG)
      <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 256 256" onload="alert(1)">
        <title>Headphones</title>
        <script>alert(1)</script>
        <foreignObject><div>hi</div></foreignObject>
        <path d="M0 0h256v256H0z" fill="#000000" style="color: red" class="icon"/>
        <a xlink:href="javascript:alert(1)"><path d="M1 1"/></a>
      </svg>
    SVG

    assert item.valid?
    assert_equal '<svg viewBox="0 0 256 256" fill="currentColor"><path d="M0 0h256v256H0z" fill="currentColor"/></svg>', item.icon_svg
  end

  test "a pasted outline icon keeps its unfilled shapes" do
    item = CustomNavigationItem.new(icon_svg: '<svg viewBox="0 0 24 24" fill="none" stroke="#111"><path d="M1 1"/></svg>')

    assert_equal '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"><path d="M1 1"/></svg>', item.icon_svg
  end

  test "label is hidden only for an icon link set to show the icon alone" do
    icon_svg = '<svg viewBox="0 0 24 24"><path d="M1 1"/></svg>'

    assert_not CustomNavigationItem.new(label: "Listening").label_hidden?
    assert_not CustomNavigationItem.new(label: "Listening", icon_svg:).label_hidden?
    assert CustomNavigationItem.new(label: "Listening", icon_svg:, show_label: false).label_hidden?
    assert navigation_items(:joel_social_bluesky).label_hidden?
  end

  test "a pasted icon must be an SVG with a viewBox" do
    [ "headphones", "<div>🎧</div>", '<svg><path d="M1 1"/></svg>' ].each do |icon_svg|
      item = CustomNavigationItem.new(blog: @blog, label: "Listening", url: "/listening", icon_svg:)

      assert_not item.valid?, icon_svg
      assert_includes item.errors[:icon_svg], "must be an SVG with a viewBox"
    end
  end
end

class PostsNavigationItemTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
  end

  test "valid with label" do
    item = PostsNavigationItem.new(blog: @blog, label: "Blog")
    assert item.valid?
  end

  test "invalid without label" do
    item = PostsNavigationItem.new(blog: @blog)
    assert_not item.valid?
    assert_includes item.errors[:label], "can't be blank"
  end

  test "label can be translated" do
    item = PostsNavigationItem.create!(blog: @blog, label: "Artículos")
    assert_equal "Artículos", item.reload.label
  end

  test "only one allowed per blog" do
    PostsNavigationItem.create!(blog: @blog, label: "Blog")

    item = PostsNavigationItem.new(blog: @blog, label: "Posts")
    assert_not item.valid?
    assert_includes item.errors[:type], "has already been taken"
  end

  test "link_url returns the posts list path" do
    item = PostsNavigationItem.new(blog: @blog, label: "Blog")
    assert_equal Rails.application.routes.url_helpers.blog_posts_list_path, item.link_url
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

  test "link_url returns url for non-email platforms" do
    assert_equal "https://bsky.app/profile/joel.example.com", @nav_item.link_url
  end

  test "link_url prepends mailto for email platform" do
    item = SocialNavigationItem.new(
      blog: @blog,
      platform: "Email",
      url: "test@example.com",
      label: "Email"
    )

    assert_equal "mailto:test@example.com", item.link_url
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

  test "external? is true for social profiles" do
    assert navigation_items(:joel_social_bluesky).external?
  end

  test "external? is false for email, page and relative custom links" do
    assert_not navigation_items(:saul_social_email).external?
    assert_not navigation_items(:joel_about).external?
    assert_not navigation_items(:joel_custom).external?
  end

  test "external? is false for a link back to the blog's own host" do
    item = CustomNavigationItem.new(blog: @blog, label: "Archive", url: "https://#{@blog.subdomain}.example.com/archive")

    assert_not item.external?
  end

  test "label follows the platform when it changes" do
    item = navigation_items(:joel_social_bluesky)

    item.update!(platform: "Mastodon", url: "https://mas.to/@joel")

    assert_equal "Mastodon", item.label
  end

  test "every social platform has an icon" do
    SocialNavigationItem::PLATFORMS.each do |platform|
      assert Rails.root.join("app/assets/images", SocialNavigationItem.new(platform:).icon).exist?, platform
    end
  end
end
