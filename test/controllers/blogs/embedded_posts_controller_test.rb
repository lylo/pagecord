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

  private

    def host_subdomain!(name)
      host! "#{name}.#{Rails.application.config.x.domain}"
    end
end
