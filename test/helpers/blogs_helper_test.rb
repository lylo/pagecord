require "test_helper"

class BlogsHelperTest < ActionView::TestCase
  include BlogsHelper
  include RoutingHelper

  test "blog title" do
    blog = blogs(:joel)
    assert_equal "Posts from @#{blog.subdomain}", blog_title(blog)

    blog.title = "My blog"
    assert_equal "My blog", blog_title(blog)
  end

  test "blog title with seo_title set" do
    blog = blogs(:joel)
    blog.title = "My blog"
    blog.seo_title = "Custom SEO Title"
    assert_equal "Custom SEO Title", blog_title(blog)
  end

  test "blog title prioritizes seo_title over title" do
    blog = blogs(:joel)
    blog.title = "Display Title"
    blog.seo_title = "SEO Title"
    assert_equal "SEO Title", blog_title(blog)
  end

  test "blog_description with no bio" do
    blog = blogs(:joel)
    blog.title = "My blog"
    blog.bio = nil
    assert_equal "My blog", blog_description(blog)
  end

  test "blog_description with bio" do
    blog = blogs(:joel)
    bio = <<~BIO
    Photographer

    https://pagecord.com/joel
    BIO

    assert_equal bio.strip, blog_description(blog)
  end

  test "blog title with home page" do
    blog = blogs(:joel)
    blog.title = "My blog"
    blog.update! home_page: posts(:about)
    assert_equal "My blog", blog_title(blog)
  end

  test "open_graph_image with open graph image present" do
    @post = posts(:one)
    @blog = @post.blog

    # Create a real OG image with attachment
    og_image = @post.create_open_graph_image!
    og_image.image.attach(
      io: StringIO.new("fake png data"),
      filename: "og-preview.png",
      content_type: "image/png"
    )

    result = open_graph_image_helper

    # Should generate URL with correct path
    assert_includes result, "/og/#{@post.token}.png"
  end

  test "open_graph_image with first image fallback" do
    @post = posts(:one)
    @post.stubs(:open_graph_image).returns(nil)

    # Mock an attachment as first image
    attachment = mock("attachment")
    @post.stubs(:first_image).returns(attachment)

    # Mock the resized_image_url helper
    stubs(:resized_image_url).with(attachment, width: 1200, height: 630, crop: true).returns("https://example.com/resized-image.jpg")

    assert_equal "https://example.com/resized-image.jpg", open_graph_image_helper
  end

  test "open_graph_image with no images returns nil" do
    @post = posts(:one)
    @post.stubs(:open_graph_image).returns(nil)
    @post.stubs(:first_image).returns(nil)
    @blog = @post.blog

    assert_nil open_graph_image_helper
  end

  test "open_graph_image with no post returns nil" do
    @post = nil
    @blog = blogs(:joel)
    stubs(:custom_domain_request?).returns(false)
    assert_nil open_graph_image_helper
  end

  private

    def open_graph_image_helper
      open_graph_image
    end
end
