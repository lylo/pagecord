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
      { 'CF-IPCountry' => 'US' }
    )
    
    # First view should be unique
    view1 = PageView.track_view(blog: blog, post: post, request: mock_request)
    assert view1.is_unique?
    
    # Second view from same visitor on same day should not be unique
    view2 = PageView.track_view(blog: blog, post: post, request: mock_request)
    assert_not view2.is_unique?
  end
end
