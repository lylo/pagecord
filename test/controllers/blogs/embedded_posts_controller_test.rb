require "test_helper"

class Blogs::EmbeddedPostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @blog = blogs(:joel)
    host_subdomain! @blog.subdomain
  end

  test "returns not found for an unsupported style" do
    get blog_embedded_posts_path(style: "grid", frame_id: "posts")

    assert_response :not_found
  end

  test "keeps filters and sort order on later pages" do
    12.times do |i|
      @blog.posts.create!(
        title: "Embedded Review #{i + 1}",
        content: "Content",
        status: :published,
        published_at: Time.zone.local(2025, 1, i + 1, 12),
        tag_list: [ "embedded-review" ]
      )
    end

    @blog.posts.create!(
      title: "Embedded Review 2024",
      content: "Content",
      status: :published,
      published_at: Time.zone.local(2024, 12, 31, 12),
      tag_list: [ "embedded-review" ]
    )

    get blog_embedded_posts_path(
      style: "stream",
      frame_id: "posts",
      page_frame_id: "embedded-posts-posts-page-2",
      page: 2,
      tag: "embedded-review",
      year: 2025,
      sort: "asc"
    )

    assert_response :success
    assert_select "turbo-frame#embedded-posts-posts-page-2"
    assert_select "turbo-stream[action='append'][target='embedded-posts-posts']"
    assert_select "body", text: /Embedded Review 11/
    assert_select "body", text: /Embedded Review 12/
    assert_select "body", text: /Embedded Review 10/, count: 0
    assert_select "body", text: /Embedded Review 2024/, count: 0

    assert_operator response.body.index("Embedded Review 11"), :<, response.body.index("Embedded Review 12")
  end

  test "by_year page continuing a year appends into that year's list" do
    DynamicVariable::PostsTag.stubs(:page_size_for).returns(3)

    get blog_embedded_posts_path(style: "by_year", frame_id: "posts", page_frame_id: "embedded-posts-posts-page-2", page: 2, last_visible_year: 2026)

    assert_response :success
    assert_select "turbo-stream[action='append'][target='embedded-posts-posts-2026'] li", count: 3
    assert_select "turbo-stream[action='replace'][target='embedded-posts-posts-page-2'] h2", count: 0
    assert_select "turbo-frame#embedded-posts-posts-page-3[src*='page=3'][src*='last_visible_year=2026']"
  end

  test "by_year page crossing into a new year starts a new group after the frame" do
    DynamicVariable::PostsTag.stubs(:page_size_for).returns(3)
    @blog.posts.create!(title: "Embedded 2025", content: "Content", status: :published, published_at: Time.zone.local(2025, 6, 1, 12))

    get blog_embedded_posts_path(style: "by_year", frame_id: "posts", page_frame_id: "embedded-posts-posts-page-3", page: 3, last_visible_year: 2026)

    assert_response :success
    assert_select "turbo-stream[action='append'][target='embedded-posts-posts-2026'] li", count: 1
    assert_select "turbo-stream[action='replace'][target='embedded-posts-posts-page-3']" do
      assert_select "h2.year-header.has-previous", text: /2025/
      assert_select "ul#embedded-posts-posts-2025 li", count: 1
      assert_select "turbo-frame", count: 0
    end
  end
end
