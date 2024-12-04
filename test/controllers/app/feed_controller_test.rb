require "test_helper"

class App::FeedControllerTest < ActionDispatch::IntegrationTest
  include AuthenticatedTest

  setup do
    @joel = users(:joel)
    @vivian = users(:vivian)
    @annie = users(:annie)

    login_as @vivian
  end

  test "should get index with no followees" do
    get app_feed_path
    assert_response :success
    assert_match "You'll see posts here once you follow people who are posting", @response.body
  end

  test "should render posts from followees" do
    @vivian.follow(@joel)

    get app_feed_path
    assert_response :success
    assert_select "article", 2
  end

  test "should get private_rss" do
    @vivian.follow(@joel)

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

  def assert_select(selector, count)
    doc = Nokogiri::HTML(@response.body)
    assert_equal count, doc.css(selector).size
  end
end
