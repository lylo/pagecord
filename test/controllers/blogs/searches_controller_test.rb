require "test_helper"

class Blogs::SearchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)

    host_subdomain! @blog.subdomain

    Rails.cache.clear
  end

  test "should render the search form without a query" do
    get blog_search_path

    assert_response :success
    assert_select "input[name=q]"
    assert_select ".post-row", count: 0
  end

  test "should list matching posts with a result count" do
    get blog_search_path(q: "photography")

    assert_response :success
    assert_select ".title_layout .post-row a", text: /Photography/i, minimum: 1
    assert_select ".tag-filter-notice", text: /\d+ posts matching photography/
  end

  test "should show empty state when nothing matches" do
    get blog_search_path(q: "xyzzy")

    assert_response :success
    assert_select ".empty-state", count: 1
  end

  test "should not include drafts" do
    get blog_search_path(q: "draft")

    assert_response :success
    assert_select ".empty-state", count: 1
  end

  test "should include pages" do
    get blog_search_path(q: "about")

    assert_response :success
    assert_select ".post-row a", text: "About"
  end

  test "should search exact phrase when quoted" do
    get blog_search_path(q: '"street photography"')

    assert_response :success
    assert_select ".post-row a", text: "The Art of Street Photography"
  end

  test "rate limited requests render the friendly too many requests page" do
    Blogs::SearchesController.any_instance.stubs(:show).raises(ActionController::TooManyRequests)

    get blog_search_path(q: "photography")

    assert_response :too_many_requests
    assert_select "h2", text: "Slow down!"
  end
end
