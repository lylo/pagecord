require "test_helper"

class Blogs::AnalyticsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @blog = blogs(:joel)
    @post = posts(:one)
    host! "#{@blog.subdomain}.example.com"
  end

  test "should create page view for blog index" do
    assert_difference("PageView.count", 1) do
      post blog_analytics_hit_path, headers: { "User-Agent" => "Mozilla/5.0 (Test Browser)" }
    end

    assert_response :no_content

    page_view = PageView.last
    assert_equal @blog, page_view.blog
    assert_nil page_view.post
    assert page_view.is_unique?
  end

  test "should create page view for specific post" do
    assert_difference("PageView.count", 1) do
      post blog_analytics_hit_path,
           params: { post_token: @post.token },
           headers: { "User-Agent" => "Mozilla/5.0 (Test Browser)" }
    end

    assert_response :no_content

    page_view = PageView.last
    assert_equal @blog, page_view.blog
    assert_equal @post, page_view.post
    assert page_view.is_unique?
  end

  test "should handle referrer from headers" do
    referrer_url = "https://google.com/search"

    post blog_analytics_hit_path,
         headers: {
           "Referer" => referrer_url,
           "User-Agent" => "Mozilla/5.0 (Test Browser)"
         }

    page_view = PageView.last
    assert_equal referrer_url, page_view.referrer
  end

  test "should handle invalid post token gracefully" do
    assert_difference("PageView.count", 1) do
      post blog_analytics_hit_path,
           params: { post_token: "invalid-token" },
           headers: { "User-Agent" => "Mozilla/5.0 (Test Browser)" }
    end

    page_view = PageView.last
    assert_nil page_view.post  # Should track as index page view when post not found
  end

  test "should not create page view for bot user agent" do
    assert_no_difference("PageView.count") do
      post blog_analytics_hit_path, headers: { "User-Agent" => "Googlebot/2.1" }
    end

    assert_response :no_content
  end


  test "should track unique visitors correctly" do
    headers = { "User-Agent" => "Mozilla/5.0 (Test Browser)" }

    # First request should be unique
    post blog_analytics_hit_path, headers: headers
    first_view = PageView.last
    assert first_view.is_unique?

    # Second request from same IP/UA on same day should not be unique
    post blog_analytics_hit_path, headers: headers
    second_view = PageView.last
    assert_not second_view.is_unique?
  end

  test "should handle Cloudflare country header" do
    post blog_analytics_hit_path,
         headers: {
           "CF-IPCountry" => "US",
           "User-Agent" => "Mozilla/5.0 (Test Browser)"
         }

    page_view = PageView.last
    assert_equal "US", page_view.country
  end
end
