require "test_helper"

class Blogs::Posts::PreviewsControllerTest < ActionDispatch::IntegrationTest
  include RoutingHelper

  setup do
    @blog = blogs(:joel)
    host_subdomain! @blog.subdomain
  end

  test "should preview a draft post with its signed token" do
    get blog_post_preview_path(posts(:joel_draft).signed_id(purpose: :preview))

    assert_response :success
    assert_select "article"
    assert_select "meta[name=robots][content='noindex, nofollow']"
    assert_equal "no-store", response.headers["Cache-Control"]
    assert_nil response.headers["Cache-Tag"]
  end

  test "should preview a draft page with its signed token" do
    get blog_post_preview_path(posts(:draft_page).signed_id(purpose: :preview))

    assert_response :success
    assert_select "article"
  end

  test "should preview a scheduled post with its signed token" do
    post = @blog.posts.create!(title: "Scheduled", content: "Soon", published_at: 1.week.from_now)

    get blog_post_preview_path(post.signed_id(purpose: :preview))

    assert_response :success
    assert_select "article"
  end

  test "should redirect a published post's preview to the post" do
    post = posts(:one)

    get blog_post_preview_path(post.signed_id(purpose: :preview))

    assert_redirected_to post_path(post)
  end

  test "should not preview with an invalid token" do
    get blog_post_preview_path("garbage")
    assert_response :not_found
  end

  test "should not preview another blog's draft" do
    get blog_post_preview_path(posts(:vivian_draft).signed_id(purpose: :preview))
    assert_response :not_found
  end
end
