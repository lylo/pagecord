require "test_helper"

class LinkedImageRenderingTest < ActionDispatch::IntegrationTest
  setup do
    @blog = users(:joel).blog
    @image = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture("space.jpg").open,
      filename: "space.jpg",
      content_type: "image/jpeg"
    )
  end

  test "wraps a linked image in an anchor" do
    post = published_post_with_image(href: "https://example.com/photos")

    get blog_post_url(subdomain: @blog.subdomain, slug: post.slug)

    assert_response :success
    assert_select "figure.attachment a[href='https://example.com/photos'] img"
    assert_select "figure.attachment figcaption a", count: 0
  end

  test "leaves an unlinked image alone" do
    post = published_post_with_image

    get blog_post_url(subdomain: @blog.subdomain, slug: post.slug)

    assert_response :success
    assert_select "figure.attachment img"
    assert_select "figure.attachment a", count: 0
  end

  private
    def published_post_with_image(href: nil)
      href_attribute = %( href="#{href}") if href

      @blog.posts.create!(
        title: "Linked image",
        content: %(<action-text-attachment sgid="#{@image.attachable_sgid}"#{href_attribute}></action-text-attachment>),
        status: :published,
        published_at: 1.minute.ago
      )
    end
end
