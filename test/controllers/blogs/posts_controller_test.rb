require "test_helper"

class Blogs::PostsControllerTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  setup do
    @blog = blogs(:joel)

    host_subdomain! @blog.subdomain
  end

  test "should get index as stream of posts" do
    get blog_posts_path

    assert_response :success
    assert_not_nil assigns(:posts)
    assert_select ".stream_layout", count: 1
  end

  test "should render a list of post titles" do
    @blog.title_layout!

    get blog_posts_path

    assert_response :success
    assert_select ".title_layout", count: 1
  end

  test "should render cards" do
    @blog.cards_layout!

    get blog_posts_path

    assert_response :success
    assert_select "div.post-card", minimum: 1
    assert_select ".cards_layout", count: 1
  end

  test "should show email subscription form on index if enabled" do
    @blog.update!(email_subscriptions_enabled: true, features: [ "email_subscribers" ])

    get blog_posts_path

    assert_response :success
    assert_select "turbo-frame#email_subscriber_form"
  end

  test "should not show email subscription form on index if show_subscription_in_header is false" do
    @blog.update!(
      email_subscriptions_enabled: true,
      show_subscription_in_header: false
    )

    get blog_posts_path

    assert_response :success
    assert_select "turbo-frame#email_subscriber_form", count: 0
  end

  test "should show email subscription form on post show if enabled" do
    @blog.update!(
      email_subscriptions_enabled: true,
      show_subscription_in_footer: true
    )
    post = @blog.posts.visible.first

    get blog_post_path(post.slug)

    assert_response :success
    assert_select "turbo-frame#email_subscriber_form"
  end

  test "should not show email subscription form on post show if show_subscription_in_footer is false" do
    @blog.update!(
      email_subscriptions_enabled: true,
      show_subscription_in_footer: false
    )
    post = @blog.posts.visible.first

    get blog_post_path(post.slug)

    assert_response :success
    assert_select "turbo-frame#email_subscriber_form", count: 0
  end

  test "should not show email subscription form on page show" do
    @blog.update!(
      email_subscriptions_enabled: true,
      show_subscription_in_footer: true
    )
    page = @blog.pages.create!(title: "Test Page", content: "Content", status: "published")

    get blog_post_path(page.slug)

    assert_response :success
    assert_select "turbo-frame#email_subscriber_form", count: 0
  end

  test "should get show" do
    post = @blog.posts.visible.first

    get blog_post_path(post.slug)

    assert_response :success
    assert_equal post, assigns(:post)
  end

  test "should include no-follow meta tag for hidden posts" do
    post = @blog.posts.create!(
      title: "Hidden Post",
      content: "This is hidden content",
      hidden: true,
      status: "published"
    )

    get blog_post_path(post.slug)

    assert_response :success
    assert_select 'meta[name="robots"][content="noindex, nofollow"]'
  end

  test "should not include no-follow meta tag for visible posts" do
    post = @blog.posts.visible.first

    get blog_post_path(post.slug)

    assert_response :success
    assert_select 'meta[name="robots"][content="noindex, nofollow"]', count: 0
  end

  test "should allow @ prefix and redirect to :name path" do
    host! Rails.application.config.x.domain

    get "/@#{@blog.subdomain}"

    assert_redirected_to "http://example.com/#{@blog.subdomain}"
  end

  test "should redirect from :name path to subdomain" do
    host! Rails.application.config.x.domain

    get "/#{@blog.subdomain}/#{posts(:one).slug}"

    assert_redirected_to "http://#{@blog.subdomain}.example.com/#{posts(:one).slug}"
  end

  test "should redirect to root if blog not found" do
    host_subdomain! "nope"

    get blog_posts_path
    assert_redirected_to "http://www.example.com/"
  end

  test "should redirect to root if user is unverified" do
    @blog = blogs(:elliot)
    host_subdomain! @blog.subdomain

    get blog_posts_path
    assert_redirected_to "http://www.example.com/"
  end

  test "should redirect to root if user is discarded" do
    @blog.user.discard!

    get blog_posts_path
    assert_redirected_to "http://www.example.com/"
  end

  ## RSS

  test "should get index as RSS" do
    get rss_feed_path(@blog)

    assert_response :success
    assert_equal "application/rss+xml; charset=utf-8", @response.content_type
  end

  test "should exclude hidden posts from RSS feed" do
    # Create a hidden post
    hidden_post = @blog.posts.create!(
      title: "Hidden Post",
      content: "This is hidden content",
      hidden: true,
      status: :published,
      published_at: 1.hour.ago
    )

    # Create a public post for comparison
    public_post = @blog.posts.create!(
      title: "Public Post",
      content: "This is public content",
      hidden: false,
      status: :published,
      published_at: 30.minutes.ago
    )

    get rss_feed_path(@blog)

    assert_response :success

    # Check that the hidden post is not in the RSS feed
    assert_not @response.body.include?("Hidden Post")
    assert_not @response.body.include?("This is hidden content")

    # Check that the public post is in the RSS feed
    assert @response.body.include?("Public Post")
    assert @response.body.include?("This is public content")
  end

  test "should redirect from old /name.rss to subdomain RSS feed" do
    host! Rails.application.config.x.domain

    get "/#{@blog.subdomain}.rss"

    assert_redirected_to "http://#{@blog.subdomain}.example.com/feed.xml"
  end

  test "should render plain text posts as html in RSS feed" do
    @blog = blogs(:vivian)
    host_subdomain! @blog.subdomain

    get rss_feed_path(@blog)

    assert_response :success

    xml = Nokogiri::XML(@response.body)
    cdata_content = xml.xpath("//item/description").first.children.find { |n| n.cdata? }.content

    assert_includes cdata_content, "<p>This is my first post.</p>"
  end

  test "should map RSS feed aliases to index" do
    get "/feed.xml"

    assert_response :success
    assert_equal "application/rss+xml; charset=utf-8", @response.content_type

    get "/feed/"

    assert_response :success
    assert_equal "application/rss+xml; charset=utf-8", @response.content_type
  end

  test "should display times in blog timezone in RSS feed" do
    post_time = 1.minute.ago

    @blog.user.update!(timezone: "America/New_York")
    @blog.posts.create!(
      published_at: post_time,
      status: "published",
      content: "Test post content"
    )

    get rss_feed_path(@blog)

    assert_response :success

    doc = Nokogiri::XML(@response.body)
    pub_date = doc.xpath("//item/pubDate").first.text
    assert_match(/-0[45]00$/, pub_date, "pubDate should include EST/EDT timezone offset")

    expected_time_in_timezone = post_time.in_time_zone("America/New_York")
    expected_hour = expected_time_in_timezone.strftime("%H")
    expected_minute = expected_time_in_timezone.strftime("%M")
    assert_match(/#{expected_hour}:#{expected_minute}:/, pub_date, "pubDate should show correct time in blog timezone")

    title = doc.xpath("//item/title").first.text
    expected_time_string = expected_time_in_timezone.to_formatted_s(:long)
    assert_match(/^@#{@blog.subdomain} - /, title, "Title should start with @subdomain - ")
    assert_includes title, expected_time_string, "Title should include the formatted local time"
  end

  test "should include tags as RSS categories in RSS feed" do
    post = @blog.posts.create!(
      title: "Tagged Post",
      content: "Post with tags",
      status: "published",
      tags_string: "ruby, rails, web-development"
    )

    get rss_feed_path(@blog)

    assert_response :success

    doc = Nokogiri::XML(@response.body)

    # Find the specific item for our tagged post by link (using slug)
    item = doc.xpath("//item[contains(link, '#{post.slug}')]").first
    assert_not_nil item, "Tagged Post should be in RSS feed"

    # Get categories only for this specific item
    categories = item.xpath("category").map(&:text)

    assert_includes categories, "ruby"
    assert_includes categories, "rails"
    assert_includes categories, "web-development"
    assert_equal 3, categories.count
  end

  # Custom domains

  test "should get index on custom domain" do
    @blog = blogs(:annie)
    host! @blog.custom_domain

    get "/"

    assert_response :success
  end

  test "should get show on custom domain" do
    @blog = blogs(:annie)
    host! @blog.custom_domain
    post = @blog.posts.visible.first

    get "/#{post.slug}"

    assert_response :success
  end

  test "should redirect to pagecord home page for unrecognised custom domain" do
    post = posts(:four)

    get "/#{post.slug}", headers: { "HOST" => "gadzooks.com" }

    assert_redirected_to "http://www.example.com/"
  end

  test "should redirect from default domain index to custom domain" do
    @blog = blogs(:annie)
    host_subdomain! @blog.subdomain
    post = @blog.posts.visible.first

    get blog_post_path(slug: post.slug)

    assert_redirected_to "http://#{post.blog.custom_domain}/#{post.slug}"
  end

  test "should redirect from default domain post to custom domain post" do
    @blog = blogs(:annie)
    host! "#{@blog.subdomain}.example.com"
    post = @blog.posts.visible.first

    get "/#{post.slug}"

    assert_redirected_to "http://#{post.blog.custom_domain}/#{post.slug}"
  end

  test "should redirect from www variant to canonical custom domain" do
    @blog = blogs(:annie)
    @blog.update!(custom_domain: "example.blog")
    host! "www.example.blog"
    post = @blog.posts.visible.first

    get "/#{post.slug}"

    assert_redirected_to "http://example.blog/#{post.slug}"
  end

  test "should redirect from root domain to www variant when canonical domain is www" do
    @blog = blogs(:annie)
    @blog.update!(custom_domain: "www.example.blog")
    host! "example.blog"
    post = @blog.posts.visible.first

    get "/#{post.slug}"

    assert_redirected_to "http://www.example.blog/#{post.slug}"
  end

  test "should not redirect when on canonical custom domain" do
    @blog = blogs(:annie)
    host! @blog.custom_domain
    post = @blog.posts.visible.first

    get "/#{post.slug}"

    assert_response :success
  end

  test "should redirect to last page on pagy overflow" do
    get blog_posts_path(page: 999)

    assert_redirected_to blog_posts_path(page: 1)
  end

  test "should redirect malformed page parameter to page 1" do
    get blog_posts_path(page: "\"><h1>Cortex</h1>2")

    assert_redirected_to blog_posts_path(page: 1)
  end

  test "should redirect negative page parameter to page 1" do
    get blog_posts_path(page: -5)

    assert_redirected_to blog_posts_path(page: 1)
  end

  test "should redirect zero page parameter to page 1" do
    get blog_posts_path(page: 0)

    assert_redirected_to blog_posts_path(page: 1)
  end

  test "should set the canonical_url to the page URL by default" do
    post = @blog.posts.visible.first

    get post_path(post)

    assert_response :success
    assert_select "link[rel=canonical][href=?]", post_url(post)
  end

  test "should set the canonical_url to the custom URL if present" do
    post = @blog.posts.visible.first
    post.update!(canonical_url: "https://myblog.net")

    get blog_post_path(post.slug)

    assert_response :success
    assert_select "link[rel=canonical][href=?]", "https://myblog.net"
  end

  test "should initially prevent free blogs from being indexed" do
    @blog = blogs(:vivian)
    host_subdomain! @blog.subdomain

    get blog_posts_path

    assert @blog.created_at.after?(1.week.ago)
    assert_select 'meta[name="robots"][content="noindex, nofollow"]'
  end

  test "should not prevent new subscribed blogs from being indexed" do
    get blog_posts_path

    assert @blog.created_at.after?(1.week.ago)
    assert_select 'meta[name="robots"][content="noindex, nofollow"]', count: 0
  end

  test "should insert author attribution into the head" do
    get blog_post_path(@blog.posts.visible.first.slug)

    assert_response :success
    assert_select 'meta[name="fediverse:creator"][content="@joel@pagecord.com"]', count: 0

    @blog.update!(fediverse_author_attribution: "@joel@pagecord.com")

    get blog_post_path(@blog.posts.visible.first.slug)

    assert_response :success
    assert_select 'meta[name="fediverse:creator"][content="@joel@pagecord.com"]'
  end

  test "should include rel='me' link if Maston social link is present" do
    get blog_posts_path

    assert_select "link[rel=\"me\"][href=\"#{@blog.social_links.mastodon.first.url}\"]"
  end

  test "should render avatar favicon when blog has an avatar" do
    @blog.avatar.attach(
      io: File.open(Rails.root.join("test/fixtures/files/avatar.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )

    get blog_posts_path

    assert_select "link[rel='apple-touch-icon'][href*='avatar']"
    assert_select "link[rel='icon'][href*='avatar']"
  end

  test "should render default favicon when blog has no avatar" do
    @blog.avatar.purge if @blog.avatar.attached?

    get blog_posts_path

    assert_select "link[rel='apple-touch-icon'][href*='/apple-touch-icon']"
    assert_select "link[rel='icon'][type='image/svg+xml'][href*='/favicon']"
  end

  test "should render upvotes for a subscriber" do
    get blog_posts_path

    assert_response :success
    assert_select "turbo-frame[id^='upvotes_post_']"
  end

  test "should not render upvotes for a non-subscriber" do
    @blog = blogs(:vivian)
    host_subdomain! "vivian"

    get blog_posts_path

    assert_response :success
    assert_select "turbo-frame[id^='upvotes_post_']", count: 0
  end

  test "should not render upvotes if show_upvotes is false" do
    @blog.update!(show_upvotes: false)

    get blog_posts_path

    assert_response :success
    assert_select "turbo-frame[id^='upvotes_post_']", count: 0
  end

  test "post published_at is stored and rendered correctly in UTC" do
    user = users(:joel)
    user.update!(timezone: "Hawaii")

    Time.use_zone(user.timezone) do
      midnight_in_hawaii = Time.zone.parse("2025-05-11 00:00:00")
      post = user.blog.posts.create!(
        content: "Time Zone Test",
        published_at: midnight_in_hawaii
      )

      # middnight_in_hawaii is 10:00 UTC
      assert_equal Time.utc(2025, 5, 11, 10), post.published_at
    end

    get blog_post_path(Post.last.slug)

    assert_select "time[datetime='2025-05-11T10:00:00Z']"
  end

  test "should pagecord branding" do
    get blog_posts_path

    assert_response :success
    assert_select "footer a[id=brand]", count: 1
  end

  test "should hide pagecord branding when show_branding off" do
    @blog.update!(show_branding: false)

    get blog_posts_path

    assert_response :success
    assert_select "footer a[id=brand]", count: 0
  end

  test "should only import font corresponding to theme" do
    get blog_posts_path

    assert_response :success
    assert_select "link[href*='ibm-plex-mono']", count: 0
    assert_select "link[href*='lora']", count: 0
    assert_select "link[href*='inter']", minimum: 1

    @blog.update!(font: "mono")

    get blog_posts_path

    assert_response :success
    assert_select "link[href*='ibm-plex-mono']", minimum: 1
    assert_select "link[href*='lora']", count: 0
    assert_select "link[href*='inter']", count: 0
  end

  test "should render google site verification meta tag when present" do
    @blog.update!(google_site_verification: "GzmHXW-PA_FXh29Dp31_cgsIx6ZY_h9OgR6r8DZ0I44")

    get blog_posts_path

    assert_response :success
    assert_select "meta[name='google-site-verification'][content='GzmHXW-PA_FXh29Dp31_cgsIx6ZY_h9OgR6r8DZ0I44']", count: 1
  end

  test "should not render google site verification meta tag when blank" do
    @blog.update!(google_site_verification: "")

    get blog_posts_path

    assert_response :success
    assert_select "meta[name='google-site-verification']", count: 0
  end

  test "should not render google site verification meta tag when nil" do
    @blog.update!(google_site_verification: nil)

    get blog_posts_path

    assert_response :success
    assert_select "meta[name='google-site-verification']", count: 0
  end

  test "should render google site verification meta tag on post show page" do
    @blog.update!(google_site_verification: "GzmHXW-PA_FXh29Dp31_cgsIx6ZY_h9OgR6r8DZ0I44")
    post = @blog.posts.visible.first

    get blog_post_path(post.slug)

    assert_response :success
    assert_select "meta[name='google-site-verification'][content='GzmHXW-PA_FXh29Dp31_cgsIx6ZY_h9OgR6r8DZ0I44']", count: 1
  end

  # Tag filtering tests

  test "should filter posts by tag" do
    # Create posts with different tags
    @blog.posts.create!(content: "Rails post", tags_string: "rails, web")
    @blog.posts.create!(content: "Python post", tags_string: "python, backend")
    @blog.posts.create!(content: "General post", tags_string: "general")

    get blog_posts_path(tag: "rails")

    assert_response :success
    assert_includes @response.body, "Rails post"
    assert_not_includes @response.body, "Python post"
    assert_not_includes @response.body, "General post"
  end

  test "should show all posts when no tag filter is applied" do
    @blog.posts.create!(content: "Rails post", tags_string: "rails")
    @blog.posts.create!(content: "Python post", tags_string: "python")

    get blog_posts_path

    assert_response :success
    assert_includes @response.body, "Rails post"
    assert_includes @response.body, "Python post"
  end

  test "should show tag filter indicator when filtering" do
    @blog.posts.create!(content: "Rails post", tags_string: "rails")

    get blog_posts_path(tag: "rails")

    assert_response :success
    assert_select "div", text: /Showing posts tagged with "rails"/
    assert_select "a[href='#{blog_posts_list_path}']", text: "Show all posts"
  end

  test "should show no posts message when tag has no matches" do
    @blog.posts.create!(content: "Rails post", tags_string: "rails")

    get blog_posts_path(tag: "nonexistent")

    assert_response :success
    assert_select "p", text: /No posts found with the tag "nonexistent"/
    assert_select "a[href='#{blog_posts_path}']", text: "View all posts"
  end

  test "should use correct page size for different layouts" do
    # Test stream layout (default)
    @blog.stream_layout!
    get blog_posts_path
    assert_response :success
    pagy = assigns(:pagy)
    assert_equal 15, pagy.limit

    # Test title layout
    @blog.title_layout!
    get blog_posts_path
    assert_response :success
    pagy = assigns(:pagy)
    assert_equal 100, pagy.limit

    # Test cards layout
    @blog.cards_layout!
    get blog_posts_path
    assert_response :success
    pagy = assigns(:pagy)
    assert_equal 15, pagy.limit
  end

  test "should not show future posts" do
    post = @blog.posts.create!(
      title: "Future Post",
      content: "This is future content",
      status: "published",
      published_at: 1.hour.from_now
    )

    get blog_post_path(post.slug)
    assert_response :not_found
  end

  test "should not show draft posts" do
    post = @blog.posts.create!(
      title: "Draft Post",
      content: "This is draft content",
      status: "draft"
    )

    get blog_post_path(post.slug)
    assert_response :not_found
  end

  test "should set locale based on blog setting" do
    @blog.update!(locale: "es")

    get blog_posts_path

    assert_equal "es", I18n.locale.to_s
    assert_response :success
  end

  test "should fall back to default locale when blog locale is nil" do
    @blog.update!(locale: "en")

    get blog_posts_path

    assert_equal "en", I18n.locale.to_s
    assert_response :success
  end

  test "should render blog 404 template for non-existent post" do
    get blog_post_path("non-existent-slug")

    assert_response :not_found
    assert_template "blogs/errors/not_found"
    assert_template layout: "application"
  end

  test "should render blog 404 template for unmatched routes" do
    get "/wp-json/activitypub/1.0/actors/-1/inbox"

    assert_response :not_found
    assert_template "blogs/errors/not_found"
    assert_template layout: "application"
  end

  test "should handle unmatched XML routes with proper 404" do
    get "/some/random/path.xml"

    assert_response :not_found
    assert_equal "", @response.body
  end

  # Home page tests

  test "should show home page instead of posts index when home page is set" do
    @blog.update!(features: [ "home_page" ])
    page = @blog.pages.create!(title: "Welcome", content: "Welcome to my blog", status: :published)
    @blog.update!(home_page_id: page.id)

    get blog_posts_path

    assert_response :success
    assert_equal page, assigns(:post)
    assert_template "blogs/posts/show"
  end

  test "should show posts index when home page is not set" do
    get blog_posts_path

    assert_response :success
    assert_not_nil assigns(:posts)
    assert_template "blogs/posts/index"
  end

  test "should still show RSS feed when home page is set" do
    @blog.update!(features: [ "home_page" ])
    page = @blog.pages.create!(title: "Welcome", content: "Welcome to my blog", status: :published)
    @blog.update!(home_page_id: page.id)

    get rss_feed_path(@blog)

    assert_response :success
    assert_equal "application/rss+xml; charset=utf-8", @response.content_type
    assert_not_nil assigns(:posts)
  end

  test "should show posts index when home page is draft" do
    @blog.update!(features: [ "home_page" ])
    page = @blog.pages.create!(title: "Welcome", content: "Welcome to my blog", status: :draft)
    @blog.update!(home_page_id: page.id)

    get blog_posts_path

    assert_response :success
    assert_not_nil assigns(:posts)
    assert_template "blogs/posts/index"
  end

  private

    def host_subdomain!(name)
      host! "#{name}.#{Rails.application.config.x.domain}"
    end
end
