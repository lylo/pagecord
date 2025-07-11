require "test_helper"

class Blogs::AuthenticationsControllerTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  setup do
    @blog = blogs(:joel)
    @blog.update!(is_private: true, password: "secret123")
    host_subdomain! @blog.subdomain
  end

  test "should show password form for private blog" do
    get blog_authentication_path

    assert_response :success
    assert_select "h1", text: "This blog is private"
    assert_select "input[type=password]"
    assert_select "input[type=submit][value='Access Blog']"
  end

  test "should redirect non-private blogs to blog home" do
    @blog.update!(is_private: false)

    get blog_authentication_path

    assert_redirected_to blog_posts_path
  end

  test "should authenticate with correct password" do
    post blog_authentication_path, params: { password: "secret123" }

    assert_redirected_to blog_posts_path
    assert_equal "Welcome to @joel!", flash[:notice]
    # Don't test the cookie value directly, just test that authentication works
  end

  test "should reject incorrect password" do
    post blog_authentication_path, params: { password: "wrong" }

    assert_response :unprocessable_entity
    assert_equal "Invalid password. Please try again.", flash[:alert]
  end

  test "should redirect to originally requested URL after authentication" do
    # Try to access a specific post - this should redirect to authentication and store the URL
    get blog_post_path(slug: "my-first-post")

    assert_redirected_to blog_authentication_path

    # Now authenticate with the correct password
    post blog_authentication_path, params: { password: "secret123" }

    # Should redirect back to the original post URL
    assert_redirected_to blog_post_path(slug: "my-first-post")
    assert_equal "Welcome to @joel!", flash[:notice]
  end

  test "should redirect to blog home if no return_to URL is stored" do
    # Direct access to authentication page (no previous URL stored)
    post blog_authentication_path, params: { password: "secret123" }

    assert_redirected_to blog_posts_path
    assert_equal "Welcome to @joel!", flash[:notice]
  end

  test "should not redirect to external URLs for security" do
    # Manually set a malicious external URL in the session
    # (This simulates what could happen if someone tampered with the session)
    get blog_authentication_path
    request.session[:return_to] = "https://evil.com/malicious"

    post blog_authentication_path, params: { password: "secret123" }

    # Should redirect to blog home instead of the external URL
    assert_redirected_to blog_posts_path
    assert_equal "Welcome to @joel!", flash[:notice]
  end

  private

    def host_subdomain!(name)
      host! "#{name}.#{Rails.application.config.x.domain}"
    end
end
