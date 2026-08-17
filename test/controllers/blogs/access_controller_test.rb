require "test_helper"

class Blogs::AccessControllerTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)
    host_subdomain! @blog.subdomain
    Rails.cache.clear
  end

  test "unprotected blog renders normally" do
    get blog_posts_path

    assert_response :success
  end

  # The gate renders over the requested page rather than redirecting, so the
  # visitor keeps their URL and never sees the access path.
  test "protected blog shows the gate in place of the index" do
    @blog.update!(password: "letmein")

    get blog_posts_path

    assert_response :unauthorized
    assert_select "form[action=?]", blog_access_path
  end

  test "protected blog shows the gate in place of a post" do
    @blog.update!(password: "letmein")
    post = posts(:one)

    get blog_post_path(post.slug)

    assert_response :unauthorized
    assert_select "input[name=return_to][value=?]", "/#{post.slug}"
    assert_no_match post.title, response.body
  end

  test "correct password grants access for subsequent requests" do
    @blog.update!(password: "letmein")

    post blog_access_path, params: { password: "letmein", return_to: "/" }
    assert_redirected_to "/"

    get blog_posts_path
    assert_response :success
  end

  test "wrong password returns to the page and grants nothing" do
    @blog.update!(password: "letmein")

    post blog_access_path, params: { password: "nope", return_to: "/" }

    assert_redirected_to "/"
    assert_equal I18n.t("private_blog.incorrect"), flash[:alert]

    get blog_posts_path
    assert_response :unauthorized
  end

  test "changing the password invalidates existing access" do
    @blog.update!(password: "letmein")
    post blog_access_path, params: { password: "letmein", return_to: "/" }

    get blog_posts_path
    assert_response :success

    @blog.update!(password: "different")

    get blog_posts_path
    assert_response :unauthorized
  end

  test "removing the password opens the blog to everyone" do
    @blog.update!(password: "letmein")
    @blog.update!(use_password: false)

    get blog_posts_path

    assert_response :success
  end

  test "granting access only redirects to local paths" do
    @blog.update!(password: "letmein")

    [ "https://evil.example.com", "//evil.example.com", "/\\evil.example.com" ].each do |hostile|
      post blog_access_path, params: { password: "letmein", return_to: hostile }

      assert_redirected_to "/"
    end
  end

  test "access returns the visitor to the page they asked for" do
    @blog.update!(password: "letmein")
    post = posts(:one)

    post blog_access_path, params: { password: "letmein", return_to: "/#{post.slug}" }

    assert_redirected_to "/#{post.slug}"
  end

  test "posting access to an unprotected blog is a no-op rather than an error" do
    post blog_access_path, params: { password: "anything", return_to: "/" }

    assert_redirected_to "/"
  end

  # A reader who has the password should be able to follow along by email –
  # that's the point of a private family blog – but the form is only reachable
  # once they're through the gate, so the password still gates the content.
  test "the gate does not offer the subscription form" do
    @blog.update!(password: "letmein", email_subscriptions_enabled: true, show_subscription_in_header: true)

    get blog_posts_path

    assert_response :unauthorized
    assert_select "form[action=?]", email_subscribers_path, false
  end

  test "a visitor with access can subscribe by email" do
    @blog.update!(password: "letmein", email_subscriptions_enabled: true)
    post blog_access_path, params: { password: "letmein", return_to: "/" }

    assert_difference -> { @blog.email_subscribers.count }, 1 do
      post email_subscribers_url(subdomain: @blog.subdomain),
        params: { blog_subdomain: @blog.subdomain, email_subscriber: { email: "gran@example.com" }, rendered_at: signed_rendered_at },
        as: :turbo_stream
    end

    assert_response :success
  end

  # Confirmation and unsubscribe links arrive by email, so they have to work
  # without the access cookie – one-click unsubscribe especially.
  test "subscription links stay reachable while the blog is locked" do
    @blog.update!(password: "letmein")
    subscriber = email_subscribers(:two)

    get email_subscriber_confirmation_path(subscriber.token)
    assert_response :success

    post email_subscriber_one_click_unsubscribe_path(subscriber.token)
    assert_response :success
    assert_not EmailSubscriber.exists?(subscriber.id)
  end

  test "the feed serves to a reader holding the token" do
    @blog.update!(password: "letmein")

    get blog_feed_xml_path(key: @blog.feed_token)

    assert_response :success
    assert_equal "application/rss+xml", response.media_type
  end

  # A feed reader can't render the gate, so a locked feed answers plainly
  # rather than handing back a page of HTML.
  test "the feed stays shut without a valid token" do
    @blog.update!(password: "letmein")

    get blog_feed_xml_path
    assert_response :unauthorized
    assert_empty response.body

    get blog_feed_xml_path(key: "nope")
    assert_response :unauthorized
  end

  # The token rides in a URL, so it must never be a way into the blog itself.
  test "the feed token opens nothing but the feed" do
    @blog.update!(password: "letmein")

    get blog_posts_path(key: @blog.feed_token)

    assert_response :unauthorized
  end

  test "the gate does not leak the feed token" do
    @blog.update!(password: "letmein")

    get blog_posts_path

    assert_response :unauthorized
    assert_no_match @blog.feed_token, response.body
    assert_select "link[type='application/rss+xml']", false
  end

  test "a visitor with access gets a feed link that works in a reader" do
    @blog.update!(password: "letmein")
    post blog_access_path, params: { password: "letmein", return_to: "/" }

    get blog_posts_path

    assert_response :success
    assert_select "link[type='application/rss+xml'][href*=?]", @blog.feed_token
  end

  test "a locked blog tells crawlers to stay out" do
    @blog.update!(password: "letmein")

    get blog_robots_path

    assert_response :success
    assert_match "Disallow: /", response.body
    assert_no_match "Sitemap:", response.body
  end
end
