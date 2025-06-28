require "test_helper"

class PostsHelperTest < ActionView::TestCase
  include ApplicationHelper

  test "post_title with title present" do
    post = posts(:one)
    assert_equal post.title, post_title(post)

    post.title = "A" * 120
    assert_equal "#{'A' * 97}...", post_title(post)
  end

  test "post_title without title present" do
    post = Blog.first.posts.build content: "Test post"
    assert_equal "Test post", post_title(post)

    post = Blog.first.posts.build content: "<p></p>"
    assert_equal "Untitled", post_title(post)

    post = Blog.first.posts.build content: "<div><p>Hello, World</p><img src='example.com'></div>"
    assert_equal "Hello, World", post_title(post)

    post = Blog.first.posts.build content: "<div><p><img src='https://example.com/image.png'></div>"
    assert_equal "Untitled", post_title(post)
  end

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

  test "open_graph_image with no images returns default" do
    @post = posts(:one)
    @post.stubs(:open_graph_image).returns(nil)
    @post.stubs(:first_image).returns(nil)
    @blog = nil

    stubs(:custom_domain_request?).returns(false)
    stubs(:image_url).with("social/open-graph.jpg").returns("https://example.com/default.jpg")

    assert_equal "https://example.com/default.jpg", open_graph_image_helper
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
