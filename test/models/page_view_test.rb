require "test_helper"

class PageViewTest < ActiveSupport::TestCase
  test "should detect bot user agents" do
    assert PageView.bot_user_agent?("Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)")
    assert PageView.bot_user_agent?("facebookexternalhit/1.1")
    assert PageView.bot_user_agent?("Mastodon/4.0.0")
    assert_not PageView.bot_user_agent?("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
  end

  test "should generate consistent visitor hash" do
    hash1 = PageView.generate_visitor_hash("127.0.0.1", "test-agent", Date.current)
    hash2 = PageView.generate_visitor_hash("127.0.0.1", "test-agent", Date.current)
    assert_equal hash1, hash2

    # Different day should generate different hash
    hash3 = PageView.generate_visitor_hash("127.0.0.1", "test-agent", 1.day.ago)
    assert_not_equal hash1, hash3
  end

  test "should track unique views correctly" do
    blog = blogs(:joel)
    post = posts(:one)

    mock_request = Struct.new(:remote_ip, :user_agent, :referrer, :fullpath, :headers).new(
      "127.0.0.1",
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      "https://google.com",
      "/test-post",
      { "CF-IPCountry" => "US" }
    )

    # First view should be created and is unique
    view1 = PageView.track(blog: blog, post: post, request: mock_request, path: "/test-post")
    assert view1.is_unique?

    # Second view from same visitor on same day should not be tracked (returns nil)
    view2 = PageView.track(blog: blog, post: post, request: mock_request, path: "/test-post")
    assert_nil view2
  end

  test "should not track bots" do
    blog = blogs(:joel)
    post = posts(:one)

    bot_request = OpenStruct.new(
      remote_ip: "1.2.3.4",
      user_agent: "Googlebot/2.1",
      referrer: nil,
      fullpath: "/",
      headers: {}
    )

    assert_nil PageView.track(blog: blog, post: post, request: bot_request, path: "/")
  end

  test "should parse path and query string correctly" do
    # Test basic path without query
    path, query = PageView.send(:parse_path_and_query, "/blog/post")
    assert_equal "/blog/post", path
    assert_nil query

    # Test path with simple query
    path, query = PageView.send(:parse_path_and_query, "/blog/post?ref=twitter")
    assert_equal "/blog/post", path
    assert_equal "ref=twitter", query

    # Test path with multiple query parameters
    path, query = PageView.send(:parse_path_and_query, "/post?utm_source=facebook&utm_medium=social&utm_campaign=test")
    assert_equal "/post", path
    assert_equal "utm_source=facebook&utm_medium=social&utm_campaign=test", query

    # Test root path
    path, query = PageView.send(:parse_path_and_query, "/")
    assert_equal "/", path
    assert_nil query

    # Test trailing slash normalisation
    path, query = PageView.send(:parse_path_and_query, "/post/")
    assert_equal "/post", path
    assert_nil query

    # Test root path with query
    path, query = PageView.send(:parse_path_and_query, "/?ref=homepage")
    assert_equal "/", path
    assert_equal "ref=homepage", query

    # Test empty/nil paths
    path, query = PageView.send(:parse_path_and_query, "")
    assert_nil path
    assert_nil query

    path, query = PageView.send(:parse_path_and_query, nil)
    assert_nil path
    assert_nil query

    # Test query string with special characters
    path, query = PageView.send(:parse_path_and_query, "/post?trk=comments_comments-list_comment-text")
    assert_equal "/post", path
    assert_equal "trk=comments_comments-list_comment-text", query
  end

  test "should store path and query string separately when tracking" do
    blog = blogs(:joel)
    post = posts(:one)

    mock_request = OpenStruct.new(
      remote_ip: "127.0.0.1",
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      referrer: "https://google.com",
      fullpath: "/test-post?utm_source=twitter",
      headers: { "CF-IPCountry" => "US" }
    )

    # Track a page view with query parameters
    view = PageView.track(blog: blog, post: post, request: mock_request, path: "/test-post?utm_source=twitter&ref=social")

    assert_equal "/test-post", view.path
    assert_equal "utm_source=twitter&ref=social", view.query_string
    assert_equal blog, view.blog
    assert_equal post, view.post
  end

  test "should handle malformed URLs gracefully" do
    # Test URL with scheme but no path (becomes root path)
    path, query = PageView.send(:parse_path_and_query, "not-a-valid-url://malformed")
    assert_equal "/", path  # Empty path becomes root
    assert_nil query

    # Test truly malformed URL that causes parse error
    path, query = PageView.send(:parse_path_and_query, "http://[invalid:url")
    assert_equal "http://[invalid:url", path  # Falls back to original
    assert_nil query

    # Test URL with only query string (no path)
    path, query = PageView.send(:parse_path_and_query, "?just=query")
    assert_equal "/", path  # Defaults to root
    assert_equal "just=query", query
  end

  test "analytics consolidation works with path grouping" do
    blog = blogs(:joel)

    # Clear any existing data
    PageView.where(blog: blog, path: "/consolidation-test").delete_all

    # Create mock requests with different IPs to avoid unique view deduplication
    base_request = {
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      referrer: nil,
      headers: { "CF-IPCountry" => "US" }
    }

    # Track same path with different query parameters
    [
      "/consolidation-test",
      "/consolidation-test?ref=twitter",
      "/consolidation-test?utm_source=facebook&utm_medium=social",
      "/consolidation-test?trk=comments"
    ].each_with_index do |full_path, i|
      request = OpenStruct.new(base_request.merge(remote_ip: "192.168.1.#{i + 1}"))
      PageView.track(blog: blog, request: request, path: full_path)
    end

    # Test that analytics group by clean path
    path_counts = blog.page_views.where(path: "/consolidation-test").group(:path).count
    assert_equal({ "/consolidation-test" => 4 }, path_counts)

    # Verify query strings are preserved
    views = blog.page_views.where(path: "/consolidation-test").order(:created_at)
    assert_equal 4, views.count

    query_strings = views.pluck(:query_string).compact.sort
    expected_queries = [ "ref=twitter", "trk=comments", "utm_source=facebook&utm_medium=social" ].sort
    assert_equal expected_queries, query_strings
  end

  test "should preserve existing behavior for paths without query strings" do
    blog = blogs(:joel)
    post = posts(:one)

    mock_request = OpenStruct.new(
      remote_ip: "127.0.0.1",
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      referrer: nil,
      headers: { "CF-IPCountry" => "US" }
    )

    view = PageView.track(blog: blog, post: post, request: mock_request, path: "/simple-path")

    assert_equal "/simple-path", view.path
    assert_nil view.query_string
    assert view.is_unique?  # Should still track uniqueness correctly
  end

  test "should store referrer_domain when tracking" do
    blog = blogs(:joel)
    post = posts(:one)

    mock_request = OpenStruct.new(
      remote_ip: "10.0.0.1",
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      headers: { "CF-IPCountry" => "US" }
    )

    view = PageView.track(blog: blog, post: post, request: mock_request, path: "/test", referrer: "https://www.google.com/search?q=test")

    assert_equal "google.com", view.referrer_domain
  end

  test "should store nil referrer_domain for direct traffic" do
    blog = blogs(:joel)
    post = posts(:one)

    mock_request = OpenStruct.new(
      remote_ip: "10.0.0.2",
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      headers: { "CF-IPCountry" => "US" }
    )

    view = PageView.track(blog: blog, post: post, request: mock_request, path: "/test", referrer: nil)

    assert_nil view.referrer_domain
  end

  test "should store country from CF-IPCountry header" do
    blog = blogs(:joel)
    post = posts(:one)

    mock_request = OpenStruct.new(
      remote_ip: "10.0.0.3",
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      headers: { "CF-IPCountry" => "DE" }
    )

    view = PageView.track(blog: blog, post: post, request: mock_request, path: "/test")

    assert_equal "DE", view.country
  end

  test "should store nil country when CF-IPCountry is XX" do
    blog = blogs(:joel)
    post = posts(:one)

    mock_request = OpenStruct.new(
      remote_ip: "10.0.0.4",
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      headers: { "CF-IPCountry" => "XX" }
    )

    view = PageView.track(blog: blog, post: post, request: mock_request, path: "/test")

    assert_nil view.country
  end

  test "should store nil country when CF-IPCountry header is missing" do
    blog = blogs(:joel)
    post = posts(:one)

    mock_request = OpenStruct.new(
      remote_ip: "10.0.0.5",
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      headers: {}
    )

    view = PageView.track(blog: blog, post: post, request: mock_request, path: "/test")

    assert_nil view.country
  end
end
