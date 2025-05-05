require "test_helper"

class Blogs::PostsControllerTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  test "should get index as stream of posts" do
    get blog_posts_path(name: blogs(:joel).name)

    assert_response :success
    assert_not_nil assigns(:posts)
    assert_select ".list-of-titles", count: 0
  end

  test "should render a list of post titles" do
    blog = blogs(:joel)
    blog.title_layout!

    get blog_posts_path(name: blog.name)

    assert_response :success
    assert_select ".list-of-titles", count: 1
  end

  test "should show email subscription form on index if enabled" do
    blog = blogs(:joel)
    blog.update!(email_subscriptions_enabled: true, features: [ "email_subscribers" ])

    get blog_posts_path(name: blogs(:joel).name)

    assert_response :success
    assert_select "turbo-frame#email_subscriber_form"
  end

  test "should get show" do
    post = posts(:one)

    get post_without_title_path(post.blog.name, post.token)

    assert_response :success
    assert_equal posts(:one), assigns(:post)
  end

  test "should allow @ prefix and redirect to blog" do
    get "/@#{blogs(:joel).name}"
    assert_redirected_to blog_posts_path(name: blogs(:joel).name)
  end

  test "should redirect to root if blog not found" do
    get blog_posts_path(name: "nope")
    assert_redirected_to root_url
  end

  test "should redirect to root if user is unverified" do
    get blog_posts_path(name: blogs(:elliot).name)
    assert_redirected_to root_url
  end

  test "should redirect to root if user is discarded" do
    blog = blogs(:joel)
    blog.user.discard!

    get blog_posts_path(name: blog.name)
    assert_redirected_to root_url
  end

  test "should get index as RSS" do
    get blog_posts_path(name: blogs(:joel).name, format: :rss)

    assert_response :success
    assert_equal "application/rss+xml; charset=utf-8", @response.content_type
  end

  test "should render plain text posts as html in RSS feed" do
    get blog_posts_path(name: blogs(:vivian).name, format: :rss)

    assert_response :success

    xml = Nokogiri::XML(@response.body)
    cdata_content = xml.xpath("//item/description").first.children.find { |n| n.cdata? }.content

    assert_includes cdata_content, "<p>This is my first post.</p>"
  end

  test "should map RSS feed aliases to index" do
    get "/#{blogs(:joel).name}/feed.xml"

    assert_response :success
    assert_equal "application/rss+xml; charset=utf-8", @response.content_type

    get "/#{blogs(:joel).name}/feed/"

    assert_response :success
    assert_equal "application/rss+xml; charset=utf-8", @response.content_type
  end

  # Custom domains

  test "should get index on custom domain" do
    post = posts(:four)

    get "/", headers: { "HOST" => post.blog.custom_domain }

    assert_response :success
  end

  test "should get show on custom domain" do
    post = posts(:four)

    get "/#{post.token}", headers: { "HOST" => post.blog.custom_domain }

    assert_response :success
  end

  test "should redirect to pagecord home page for unrecognised custom domain" do
    post = posts(:four)

    get "/#{post.token}", headers: { "HOST" => "gadzooks.com" }

    assert_redirected_to "http://www.example.com/"
  end

  test "should redirect from default domain index to custom domain" do
    post = posts(:four)

    get post_without_title_path(name: post.blog.name, token: post.token)

    assert_redirected_to "http://#{post.blog.custom_domain}/#{post.token}"
  end

  test "should redirect from default domain post to custom domain post" do
    post = posts(:four)

    get "/#{post.blog.name}/#{post.token}"

    assert_redirected_to "http://#{post.blog.custom_domain}/#{post.token}"
  end

  test "should redirect to last page on pagy overflow" do
    get blog_posts_path(name: blogs(:joel).name, page: 999)

    assert_redirected_to blog_posts_path(name: blogs(:joel).name, page: 1)
  end

  test "should set the canonical_url to the page URL by default" do
    post = posts(:one)
    get post_without_title_path(post.blog.name, post.token)

    assert_response :success
    assert_select "link[rel=canonical][href=?]", post_without_title_url(post.blog.name, post.token)
  end

  test "should set the canonical_url to the custom URL if present" do
    post = posts(:one)
    post.update!(canonical_url: "https://myblog.net")

    get post_without_title_path(post.blog.name, post.token)

    assert_response :success
    assert_select "link[rel=canonical][href=?]", "https://myblog.net"
  end

  test "should initially prevent free blogs from being indexed" do
    blog = blogs(:vivian)
    get "/#{blog.name}"

    assert blog.created_at.after?(1.week.ago)
    assert_select 'meta[name="robots"][content="noindex, nofollow"]'
  end

  test "should not prevent new subscribed blogs from being indexed" do
    blog = blogs(:joel)
    get "/#{blog.name}"

    assert blog.created_at.after?(1.week.ago)
    assert_select 'meta[name="robots"][content="noindex, nofollow"]', count: 0
  end

  test "should insert author attribution into the head" do
    blog = blogs(:joel)

    get post_without_title_path(blog.name, blog.posts.visible.first.token)

    assert_response :success
    assert_select 'meta[name="fediverse:creator"][content="@joel@pagecord.com"]', count: 0

    blog.update!(fediverse_author_attribution: "@joel@pagecord.com")

    assert_response :success
    get post_without_title_path(blog.name, blog.posts.visible.first.token)

    assert_select 'meta[name="fediverse:creator"][content="@joel@pagecord.com"]'
  end

  test "should include rel='me' link if Maston social link is present" do
    blog = blogs(:joel)

    get "/#{blog.name}"

    assert_select "link[rel=\"me\"][href=\"#{blog.social_links.mastodon.first.url}\"]"
  end

  test "should render avatar favicon when blog has an avatar" do
    blog = blogs(:joel)

    blog.avatar.attach(
      io: File.open(Rails.root.join("test/fixtures/files/avatar.png")),
      filename: "avatar.png",
      content_type: "image/png"
    )

    get "/#{blog.name}"

    assert_select "link[rel='apple-touch-icon'][href*='avatar']"
    assert_select "link[rel='icon'][type='image/png'][href*='avatar']"
  end

  test "should render default favicon when blog has no avatar" do
    blog = blogs(:joel)

    blog.avatar.purge if blog.avatar.attached?

    get "/#{blog.name}"

    assert_select "link[rel='apple-touch-icon'][href*='/assets/apple-touch-icon']"
    assert_select "link[rel='icon'][type='image/svg+xml'][href*='/assets/favicon']"
  end
end
