require "test_helper"

class Blogs::PostsControllerTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  test "should get index" do
    get blog_posts_path(name: blogs(:joel).name)

    assert_response :success
    assert_not_nil assigns(:posts)
  end

  test "should get show" do
    post = posts(:one)

    get post_without_title_path(post.blog.name, post.token)

    assert_response :success
    assert_equal posts(:one), assigns(:post)
  end

  test "should allow @ prefix and redirect to blog" do
    get "/@#{blogs(:joel).name}"
    assert_redirected_to blog_posts_path(name: blogs(:joel).name)
  end

  test "should redirect to root if blog not found" do
    get blog_posts_path(name: "nope")
    assert_redirected_to root_url
  end

  test "should redirect to root if user is unverified" do
    get blog_posts_path(name: blogs(:elliot).name)
    assert_redirected_to root_url
  end

  test "should redirect to root if user is discarded" do
    blog = blogs(:joel)
    blog.user.discard!

    get blog_posts_path(name: blog.name)
    assert_redirected_to root_url
  end

  test "should get index as RSS" do
    get blog_posts_path(name: blogs(:joel).name, format: :rss)

    assert_response :success
    assert_equal "application/rss+xml; charset=utf-8", @response.content_type
  end

  test "should render plain text posts as html in RSS feed" do
    get blog_posts_path(name: blogs(:vivian).name, format: :rss)

    assert_response :success

    xml = Nokogiri::XML(@response.body)
    cdata_content = xml.xpath("//item/description").first.children.find { |n| n.cdata? }.content

    assert_includes cdata_content, "<p>This is my first post.</p>"
  end

  # Custom domains

  test "should get index on custom domain" do
    post = posts(:four)

    get "/", headers: { "HOST" => post.blog.custom_domain }

    assert_response :success
  end

  test "should get show on custom domain" do
    post = posts(:four)

    get "/#{post.token}", headers: { "HOST" => post.blog.custom_domain }

    assert_response :success
  end

  test "should redirect to pagecord home page for unrecognised custom domain" do
    post = posts(:four)

    get "/#{post.token}", headers: { "HOST" => "gadzooks.com" }

    assert_redirected_to "http://www.example.com/"
  end

  test "should redirect from default domain index to custom domain" do
    post = posts(:four)

    get post_without_title_path(name: post.blog.name, token: post.token)

    assert_redirected_to "http://#{post.blog.custom_domain}/#{post.token}"
  end

  test "should redirect from default domain post to custom domain post" do
    post = posts(:four)

    get "/#{post.blog.name}/#{post.token}"

    assert_redirected_to "http://#{post.blog.custom_domain}/#{post.token}"
  end

  test "should redirect to last page on pagy overflow" do
    get blog_posts_path(name: blogs(:joel).name, page: 999)

    assert_redirected_to blog_posts_path(name: blogs(:joel).name, page: 1)
  end
end