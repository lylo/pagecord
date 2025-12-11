require "test_helper"

class Blogs::PageViewsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @blog = blogs(:joel)
    @post = posts(:one)
    host! "#{@blog.subdomain}.example.com"
  end

  test "should create page view for blog index" do
    assert_difference("PageView.count", 1) do
      post blog_page_views_path,
           params: { path: "/" }.to_json,
           headers: json_headers
    end

    assert_response :no_content

    page_view = PageView.last
    assert_equal @blog, page_view.blog
    assert_nil page_view.post
    assert page_view.is_unique?
  end

  test "should create page view for specific post" do
    assert_difference("PageView.count", 1) do
      post blog_page_views_path,
           params: { path: "/posts/#{@post.slug}", post_token: @post.token }.to_json,
           headers: json_headers
    end

    assert_response :no_content

    page_view = PageView.last
    assert_equal @blog, page_view.blog
    assert_equal @post, page_view.post
    assert page_view.is_unique?
  end

  test "should handle referrer" do
    referrer_url = "https://google.com/search"

    post blog_page_views_path,
         params: { path: "/", referrer: referrer_url }.to_json,
         headers: json_headers

    page_view = PageView.last
    assert_equal referrer_url, page_view.referrer
  end

  test "should handle invalid post token gracefully" do
    assert_difference("PageView.count", 1) do
      post blog_page_views_path,
           params: { path: "/", post_token: "invalid-token" }.to_json,
           headers: json_headers
    end

    page_view = PageView.last
    assert_nil page_view.post
  end

  test "should not create page view for bot user agent" do
    assert_no_difference("PageView.count") do
      post blog_page_views_path,
           params: { path: "/" }.to_json,
           headers: { "Content-Type" => "application/json", "User-Agent" => "Googlebot/2.1" }
    end

    assert_response :no_content
  end

  test "should track unique visitors only" do
    # First request should be unique
    assert_difference("PageView.count", 1) do
      post blog_page_views_path,
           params: { path: "/" }.to_json,
           headers: json_headers
    end

    # Second request from same IP/UA on same day should not record page view
    assert_no_difference("PageView.count") do
      post blog_page_views_path,
           params: { path: "/" }.to_json,
           headers: json_headers
    end
  end

  private

    def json_headers
      { "Content-Type" => "application/json", "User-Agent" => "Mozilla/5.0 (Test Browser)" }
    end
end
