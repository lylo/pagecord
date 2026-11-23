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

  test "lazy-loads images" do
    post = published_post_with_image

    get blog_post_url(subdomain: @blog.subdomain, slug: post.slug)

    assert_select "figure.attachment img[loading=lazy]"
  end

  test "sizes images so they hold their space before loading" do
    @image.update!(metadata: { "width" => 4000, "height" => 3000 })
    post = published_post_with_image

    get blog_post_url(subdomain: @blog.subdomain, slug: post.slug)

    assert_select "figure.attachment img[width='1600'][height='1200']"
  end

  private
    def published_post_with_image(href: nil)
      @blog.posts.create!(
        title: "Linked image",
        content: %(<action-text-attachment sgid="#{@image.attachable_sgid}"#{%( href="#{href}") if href}></action-text-attachment>),
        status: :published,
        published_at: 1.minute.ago
      )
    end
end
