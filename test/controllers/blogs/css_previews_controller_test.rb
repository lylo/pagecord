require "test_helper"

class Blogs::CssPreviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)
    host_subdomain! @blog.subdomain
    Rails.stubs(:cache).returns(ActiveSupport::Cache::MemoryStore.new)
    Rails.cache.write("css_preview:#{@blog.id}:abc123", ".blog { color: rebeccapurple; }")
  end

  test "should render the blog with the stashed CSS and never cache it" do
    get blog_css_preview_url("abc123")

    assert_response :success
    assert_includes response.body, "rebeccapurple"
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_nil response.headers["Cache-Tag"]
  end

  test "should preview the custom home page when the blog has one" do
    home_page = posts(:about)
    @blog.update!(home_page_id: home_page.id)

    get blog_css_preview_url("abc123")

    assert_response :success
    assert_includes response.body, "rebeccapurple"
    assert_includes response.body, home_page.title
    assert_equal "no-store", response.headers["Cache-Control"]
  end

  test "should not find an unknown or expired token" do
    get blog_css_preview_url("nope")

    assert_response :not_found
  end

  test "should not find another blog's token" do
    host_subdomain! blogs(:vivian).subdomain

    get blog_css_preview_url("abc123")

    assert_response :not_found
  end
end
