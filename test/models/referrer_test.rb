require "test_helper"

class ReferrerTest < ActiveSupport::TestCase
  test "extracts domain from URL" do
    assert_equal "google.com", Referrer.new("https://www.google.com/search?q=test").domain
    assert_equal "x.com", Referrer.new("https://twitter.com/user/status/123").domain  # Normalized to x.com
    assert_equal "news.ycombinator.com", Referrer.new("https://news.ycombinator.com/item?id=123").domain
  end

  test "removes www prefix from domain" do
    assert_equal "google.com", Referrer.new("https://www.google.com").domain
    assert_equal "example.com", Referrer.new("http://www.example.com/page").domain
  end

  test "returns nil for blank URL" do
    assert_nil Referrer.new(nil).domain
    assert_nil Referrer.new("").domain
  end

  test "returns nil for invalid URL" do
    assert_nil Referrer.new("not a url").domain
  end

  test "direct? returns true for blank/nil URL" do
    assert Referrer.new(nil).direct?
    assert Referrer.new("").direct?
  end

  test "direct? returns false for valid URL" do
    assert_not Referrer.new("https://google.com").direct?
  end

  test "friendly_name returns Direct for direct traffic" do
    assert_equal "Direct", Referrer.new(nil).friendly_name
    assert_equal "Direct", Referrer.new("").friendly_name
  end

  test "friendly_name returns known source name" do
    assert_equal "Google", Referrer.new("https://www.google.com/search").friendly_name
    assert_equal "X", Referrer.new("https://twitter.com").friendly_name
    assert_equal "X", Referrer.new("https://t.co/abc123").friendly_name
    assert_equal "X", Referrer.new("https://x.com").friendly_name
    assert_equal "Hacker News", Referrer.new("https://news.ycombinator.com").friendly_name
    assert_equal "Reddit", Referrer.new("https://old.reddit.com/r/rails").friendly_name
    assert_equal "GitHub", Referrer.new("https://github.com/user/repo").friendly_name
  end

  test "friendly_name returns domain for unknown sources" do
    assert_equal "example.com", Referrer.new("https://example.com").friendly_name
    assert_equal "myblog.net", Referrer.new("https://myblog.net/post/123").friendly_name
  end

  test "icon_path returns person icon for direct traffic" do
    assert_equal "icons/person.svg", Referrer.new(nil).icon_path
  end

  test "icon_path returns search icon for search engines" do
    assert_equal "icons/search.svg", Referrer.new("https://google.com").icon_path
    assert_equal "icons/search.svg", Referrer.new("https://bing.com").icon_path
    assert_equal "icons/search.svg", Referrer.new("https://duckduckgo.com").icon_path
  end

  test "icon_path returns social icons for social platforms" do
    assert_equal "icons/social/x.svg", Referrer.new("https://twitter.com").icon_path
    assert_equal "icons/social/reddit.svg", Referrer.new("https://reddit.com").icon_path
    assert_equal "icons/social/linkedin.svg", Referrer.new("https://linkedin.com").icon_path
  end

  test "icon_path returns web icon for unknown sources" do
    assert_equal "icons/social/web.svg", Referrer.new("https://example.com").icon_path
  end

  test "search_engine? returns true for search engines" do
    assert Referrer.new("https://google.com").search_engine?
    assert Referrer.new("https://bing.com").search_engine?
    assert_not Referrer.new("https://twitter.com").search_engine?
    assert_not Referrer.new(nil).search_engine?
  end

  test "social? returns true for social platforms" do
    assert Referrer.new("https://twitter.com").social?
    assert Referrer.new("https://reddit.com").social?
    assert_not Referrer.new("https://google.com").social?
    assert_not Referrer.new(nil).social?
  end

  test "handles international Google domains" do
    assert_equal "Google", Referrer.new("https://google.co.uk").friendly_name
    assert_equal "Google", Referrer.new("https://google.de").friendly_name
    assert_equal "Google", Referrer.new("https://google.fr").friendly_name
  end

  test "normalizes twitter.com and t.co to x.com" do
    assert_equal "x.com", Referrer.new("https://twitter.com/user").domain
    assert_equal "x.com", Referrer.new("https://t.co/abc123").domain
    assert_equal "x.com", Referrer.new("https://x.com/user").domain
  end

  test "normalizes old.reddit.com to reddit.com" do
    assert_equal "reddit.com", Referrer.new("https://old.reddit.com/r/rails").domain
    assert_equal "reddit.com", Referrer.new("https://reddit.com/r/rails").domain
  end

  test "normalizes international Google domains to google.com" do
    assert_equal "google.com", Referrer.new("https://google.co.uk").domain
    assert_equal "google.com", Referrer.new("https://google.de").domain
    assert_equal "google.com", Referrer.new("https://www.google.fr").domain
    assert_equal "google.com", Referrer.new("https://google.com").domain
  end
end
