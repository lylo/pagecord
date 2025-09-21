require "test_helper"

class Blogs::CanonicalDomainTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)
    @blog.update!(custom_domain: "myblog.net")
  end

  test "serves content on canonical domain" do
    host! "myblog.net"
    get "/"

    assert_response :success
  end

  test "redirects from www variant to canonical domain" do
    host! "www.myblog.net"
    get "/"

    assert_response :moved_permanently
    assert_redirected_to "http://myblog.net/"
  end

  test "redirects from non-www variant when canonical is www" do
    @blog.update!(custom_domain: "www.myblog.net")
    host! "myblog.net"
    get "/"

    assert_response :moved_permanently
    assert_redirected_to "http://www.myblog.net/"
  end

  test "preserves path in redirect from variant to canonical" do
    host! "www.myblog.net"
    get "/some-post"

    assert_response :moved_permanently
    assert_redirected_to "http://myblog.net/some-post"
  end

  test "preserves query string in redirect from variant to canonical" do
    host! "www.myblog.net"
    get "/?param=value&other=test"

    assert_response :moved_permanently
    assert_redirected_to "http://myblog.net/?param=value&other=test"
  end

  test "preserves both path and query string in redirect" do
    host! "www.myblog.net"
    get "/nested/path?param=value"

    assert_response :moved_permanently
    assert_redirected_to "http://myblog.net/nested/path?param=value"
  end

  test "redirects to app home for non-existent domain" do
    host! "nonexistent.com"
    get "/"

    assert_redirected_to "http://www.example.com/"
  end

  test "redirects to app home for variant when no blog configured for either domain" do
    host! "www.nonexistent.com"
    get "/"

    assert_redirected_to "http://www.example.com/"
  end
end
