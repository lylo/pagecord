require "test_helper"

class BlogsHelperTest < ActionView::TestCase
  include BlogsHelper

  test "blog title" do
    blog = blogs(:joel)
    assert_equal "Posts from @#{blog.subdomain}", blog_title(blog)

    blog.title = "My blog"
    assert_equal "My blog", blog_title(blog)
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

  test "open_graph_image with open graph image present" do
    @post = posts(:one)
    open_graph_image = OpenGraphImage.new(url: "https://example.com/og-image.jpg")
    @post.stubs(:open_graph_image).returns(open_graph_image)

    assert_equal "https://example.com/og-image.jpg", open_graph_image_helper
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
