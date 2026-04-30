require "test_helper"

class RoutingHelperTest < ActionView::TestCase
  include RoutingHelper

  test "rss_feed_url uses subdomain as the URL host" do
    blog = blogs(:joel)

    url = rss_feed_url(blog, tag: "photography")

    assert_equal "http://#{blog.subdomain}.example.com/feed.xml?tag=photography", url
    refute_includes url, "host="
  end

  test "rss_feed_url uses custom domain as the URL host" do
    blog = blogs(:annie)

    url = rss_feed_url(blog, tag: "photography")

    assert_equal "http://#{blog.custom_domain}/feed.xml?tag=photography", url
    refute_includes url, "host="
  end

  test "rss_feed_path does not leak host into the query string" do
    blog = blogs(:joel)

    path = rss_feed_path(blog)

    assert_equal "/feed.xml", path
    refute_includes path, "host="
  end
end
