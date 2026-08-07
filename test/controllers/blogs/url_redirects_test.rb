require "test_helper"

class Blogs::UrlRedirectsTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)
    @post = @blog.posts.visible.first

    host_subdomain! @blog.subdomain

    Rails.cache.clear
  end

  test "redirects an exact rule" do
    @blog.update!(redirect_rules: "/old-path /new-path")

    get "/old-path"

    assert_redirected_to "/new-path"
    assert_equal 301, @response.status
  end

  test "redirects a wildcard rule with substitution" do
    @blog.update!(redirect_rules: "/wp/* /*")

    get "/wp/#{@post.slug}"

    assert_redirected_to "/#{@post.slug}"
    assert_equal 301, @response.status
  end

  test "rules never shadow live content" do
    @blog.update!(redirect_rules: "/#{@post.slug} /somewhere-else")

    get "/#{@post.slug}"

    assert_response :success
  end

  test "a self-referencing rule renders a 404 instead of looping" do
    @blog.update!(redirect_rules: "/gone /gone")

    get "/gone"

    assert_response :not_found
  end

  test "falls back to the slug for dated paths" do
    get "/2024/01/#{@post.slug}"

    assert_redirected_to "/#{@post.slug}"
    assert_equal 301, @response.status
  end

  test "falls back to the slug for arbitrary prefixes with html suffix" do
    get "/archives/#{@post.slug}.html"

    assert_redirected_to "/#{@post.slug}"
    assert_equal 301, @response.status
  end

  test "renders a 404 when nothing matches" do
    get "/2024/01/no-such-post"

    assert_response :not_found
  end

  test "does not redirect POST requests" do
    @blog.update!(redirect_rules: "/old-path /new-path")

    post "/old-path"

    assert_response :not_found
  end

  test "redirects common feed URLs to the canonical feed" do
    get "/rss"
    assert_redirected_to "/feed.xml"

    get "/rss.xml"
    assert_redirected_to "/feed.xml"

    get "/blog/feed.xml"
    assert_redirected_to "/feed.xml"
    assert_equal 301, @response.status
  end

  test "custom domain canonicalisation takes precedence over redirects" do
    @blog = blogs(:annie)
    @blog.update!(redirect_rules: "/old-path /new-path")
    host_subdomain! @blog.subdomain

    get "/old-path"

    assert_redirected_to "http://#{@blog.custom_domain}/old-path"
    assert_equal 301, @response.status
  end
end
