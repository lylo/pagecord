require "test_helper"

class Blogs::UnlockControllerTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)
    host_subdomain! @blog.subdomain
    Rails.cache.clear
  end

  test "unprotected blog renders normally" do
    get blog_posts_path

    assert_response :success
  end

  test "protected blog redirects the index to the unlock page" do
    @blog.update!(password: "letmein")

    get blog_posts_path

    assert_redirected_to blog_unlock_path(return_to: "/")
  end

  test "protected blog redirects a post to the unlock page" do
    @blog.update!(password: "letmein")
    post = posts(:one)

    get blog_post_path(post.slug)

    assert_redirected_to blog_unlock_path(return_to: "/#{post.slug}")
  end

  test "correct password unlocks the blog for subsequent requests" do
    @blog.update!(password: "letmein")

    post blog_unlock_path, params: { password: "letmein", return_to: "/" }
    assert_redirected_to "/"

    get blog_posts_path
    assert_response :success
  end

  test "wrong password re-renders the form and does not unlock" do
    @blog.update!(password: "letmein")

    post blog_unlock_path, params: { password: "nope" }
    assert_response :unprocessable_entity

    get blog_posts_path
    assert_redirected_to blog_unlock_path(return_to: "/")
  end

  test "changing the password invalidates an existing unlock" do
    @blog.update!(password: "letmein")
    post blog_unlock_path, params: { password: "letmein", return_to: "/" }

    get blog_posts_path
    assert_response :success

    @blog.update!(password: "different")

    get blog_posts_path
    assert_redirected_to blog_unlock_path(return_to: "/")
  end

  test "unlock create only redirects to local paths" do
    @blog.update!(password: "letmein")

    post blog_unlock_path, params: { password: "letmein", return_to: "https://evil.example.com" }

    assert_redirected_to "/"
  end

  test "new redirects away when the blog is not protected" do
    get blog_unlock_path

    assert_redirected_to "/"
  end
end
