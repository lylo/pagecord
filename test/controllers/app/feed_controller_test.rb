require "test_helper"

class App::FeedControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @joel = users(:joel)
    @vivian = users(:vivian)
    @annie = users(:annie)

    login_as @vivian
  end

  test "should get index with no followed blogs" do
    get app_feed_path
    assert_response :success
    assert_match "You'll see posts here once you follow people who are posting", @response.body
  end

  test "should render posts from followed blogs" do
    @vivian.follow(@joel.blog)

    get app_feed_path
    assert_response :success
    assert_select "article", @joel.blog.posts.published.count
  end

  test "should get private_rss" do
    @vivian.follow(@joel.blog)

    get app_private_rss_feed_path(token: "joel_gf35jsue", format: :rss)
    assert_response :success
  end

  test "should get private_rss when not logged in" do
    get app_private_rss_feed_path(token: "vivian_jfur73yd", format: :rss)
    assert_response :success
  end

  test "private_rss should return not authorised with invalid token" do
    get app_private_rss_feed_path(token: "nope", format: :rss)
    assert_response :unauthorized
  end

  test "private_rss should include tags as RSS categories" do
    # Create a post with tags in followed blog
    post = @joel.blog.posts.create!(
      title: "Tagged Post",
      content: "Post with tags",
      status: "published",
      tags_string: "ruby, rails, web-development"
    )

    @vivian.follow(@joel.blog)

    get app_private_rss_feed_path(token: "vivian_jfur73yd", format: :rss)
    assert_response :success

    doc = Nokogiri::XML(@response.body)

    # Find the specific item for our tagged post by link (using slug)
    item = doc.xpath("//item[contains(link, '#{post.slug}')]").first
    assert_not_nil item, "Tagged Post should be in RSS feed"

    # Get categories only for this specific item
    categories = item.xpath("category").map(&:text)

    assert_includes categories, "ruby"
    assert_includes categories, "rails"
    assert_includes categories, "web-development"
    assert_equal 3, categories.count
  end

  def assert_select(selector, count)
    doc = Nokogiri::HTML(@response.body)
    assert_equal count, doc.css(selector).size
  end
end
