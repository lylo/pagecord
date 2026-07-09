require "test_helper"

class Blogs::RedirectsControllerTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  setup do
    @blog = blogs(:joel)

    host_subdomain! @blog.subdomain

    Rails.cache.clear
  end

  test "redirects a prefixed posts path to the canonical post URL" do
    post = @blog.posts.visible.first

    get "/posts/#{post.slug}"

    assert_redirected_to "http://#{@blog.subdomain}.example.com/#{post.slug}"
    assert_equal 301, @response.status
  end

  test "does not redirect a prefixed posts path for pages" do
    page = @blog.all_posts.create!(title: "About", content: "About content", status: :published, is_page: true)

    get "/posts/#{page.slug}"

    assert_response :not_found
  end

  test "lets the custom domain redirect take precedence" do
    @blog = blogs(:annie)
    host_subdomain! @blog.subdomain
    post = @blog.posts.visible.first

    get "/posts/#{post.slug}"

    assert_redirected_to "http://#{@blog.custom_domain}/posts/#{post.slug}"
    assert_equal 301, @response.status
  end

  test "redirects a prefixed posts path for hidden posts" do
    post = @blog.posts.create!(
      title: "Hidden Post",
      content: "This is hidden content",
      status: :published,
      hidden: true
    )

    get "/posts/#{post.slug}"

    assert_redirected_to "http://#{@blog.subdomain}.example.com/#{post.slug}"
    assert_equal 301, @response.status
  end

  test "does not redirect a prefixed posts path for draft posts" do
    post = @blog.posts.create!(title: "Draft Post", content: "Draft content", status: :draft)

    get "/posts/#{post.slug}"

    assert_response :not_found
  end

  test "does not redirect a prefixed posts path for future posts" do
    post = @blog.posts.create!(
      title: "Future Post",
      content: "Future content",
      status: :published,
      published_at: 1.day.from_now
    )

    get "/posts/#{post.slug}"

    assert_response :not_found
  end

  test "does not redirect a prefixed posts path for missing content" do
    get "/posts/missing"

    assert_response :not_found
  end

  test "keeps the posts archive route ahead of the prefixed posts redirect" do
    get "/posts"

    assert_response :success
    assert_template "blogs/posts/index"
  end

  test "keeps the embedded posts route ahead of the prefixed posts redirect" do
    get "/posts/embedded", params: { style: "card", frame_id: "posts" }

    assert_response :success
    assert_template "blogs/embedded_posts/index"
  end
end
