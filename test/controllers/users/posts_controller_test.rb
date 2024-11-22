require "test_helper"

class Users::PostsControllerTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  test "should get index" do
    get user_posts_path(username: users(:joel).username)

    assert_response :success
    assert_not_nil assigns(:posts)
  end

  test "should get show" do
    post = posts(:one)

    get post_without_title_path(post.user.username, post.token)

    assert_response :success
    assert_equal posts(:one), assigns(:post)
  end

  test "should allow @ prefix and redirect to user" do
    get "/@#{users(:joel).username}"
    assert_redirected_to user_posts_path(username: users(:joel).username)
  end

  test "should redirect to root if user not found" do
    get user_posts_path(username: "nope")
    assert_redirected_to root_url
  end

  test "should redirect to root if user is unverified" do
    get user_posts_path(username: users(:elliot).username)
    assert_redirected_to root_url
  end

  test "should get index as RSS" do
    get user_posts_path(username: users(:joel).username, format: :rss)

    assert_response :success
    assert_equal "application/rss+xml; charset=utf-8", @response.content_type
  end

  test "should render plain text posts as html in RSS feed" do
    get user_posts_path(username: users(:vivian).username, format: :rss)

    assert_response :success

    xml = Nokogiri::XML(@response.body)
    cdata_content = xml.xpath("//item/description").first.children.find { |n| n.cdata? }.content

    assert_includes cdata_content, "<p>This is my first post.</p>"
  end

  # Custom domains

  test "should get index on custom domain" do
    post = posts(:four)

    get "/", headers: { "HOST" => post.user.custom_domain }

    assert_response :success
  end

  test "should get show on custom domain" do
    post = posts(:four)

    get "/#{post.token}", headers: { "HOST" => post.user.custom_domain }

    assert_response :success
  end

  test "should redirect to pagecord home page for unrecognised custom domain" do
    post = posts(:four)

    get "/#{post.token}", headers: { "HOST" => "gadzooks.com" }

    assert_redirected_to "http://www.example.com/"
  end

  test "should redirect from default domain username index to custom domain" do
    post = posts(:four)

    get post_without_title_path(username: post.user.username, token: post.token)

    assert_redirected_to "http://#{post.user.custom_domain}/#{post.token}"
  end

  test "should redirect from default domain username post to custom domain post" do
    post = posts(:four)

    get "/#{post.user.username}/#{post.token}"

    assert_redirected_to "http://#{post.user.custom_domain}/#{post.token}"
  end

  test "should redirect to last page on pagy overflow" do
    get user_posts_path(username: users(:joel).username, page: 999)

    assert_redirected_to user_posts_path(username: users(:joel).username, page: 1)
  end
end
