require "test_helper"
require "mocha/minitest"

class BlogsHelperTest < ActionView::TestCase
  include BlogsHelper

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

  test "open_graph_image with dynamic OG worker URL configured" do
    @post = posts(:one)
    @post.stubs(:open_graph_image).returns(nil)
    @post.stubs(:first_image).returns(nil)
    @post.stubs(:display_title).returns("My Blog Post")
    @blog = @post.blog
    @blog.stubs(:display_name).returns("Joel's Blog")
    @blog.stubs(:avatar).returns(stub(attached?: false))

    # Temporarily configure worker URL via ENV
    ENV.stubs(:[]).with("OG_WORKER_URL").returns("https://og.example.com/og")
    ENV.stubs(:[]).with("OG_SIGNING_SECRET").returns(nil)

    # Mock feature flag to be enabled
    stubs(:feature?).with(:dynamic_open_graph, blog: @blog).returns(true)

    # Mock request for default favicon URL
    stubs(:request).returns(stub(protocol: "http://", host_with_port: "example.com:3000"))

    result = open_graph_image_helper
    uri = URI.parse(result)
    params = CGI.parse(uri.query)

    assert_equal "https", uri.scheme
    assert_equal "og.example.com", uri.host
    assert_equal "/og", uri.path
    assert_equal [ "My Blog Post" ], params["title"]
    assert_equal [ "Joel's Blog" ], params["blogTitle"]
    assert_equal [ "http://example.com:3000/apple-touch-icon.png" ], params["avatar"]
  end

  test "open_graph_image with dynamic OG disabled returns nil" do
    @post = posts(:one)
    @post.stubs(:open_graph_image).returns(nil)
    @post.stubs(:first_image).returns(nil)
    @blog = @post.blog

    # Configure worker URL via ENV
    ENV.stubs(:[]).with("OG_WORKER_URL").returns("https://og.example.com/og")
    ENV.stubs(:[]).with("OG_SIGNING_SECRET").returns(nil)

    # Mock feature flag to be disabled
    stubs(:feature?).with(:dynamic_open_graph, blog: @blog).returns(false)

    assert_nil open_graph_image_helper
  end

  test "open_graph_image with dynamic OG worker URL and avatar" do
    @post = posts(:one)
    @post.stubs(:open_graph_image).returns(nil)
    @post.stubs(:first_image).returns(nil)
    @post.stubs(:display_title).returns("My Blog Post")
    @blog = @post.blog
    @blog.stubs(:display_name).returns("Joel's Blog")

    # Mock avatar
    avatar = mock("avatar")
    avatar.stubs(:attached?).returns(true)
    @blog.stubs(:avatar).returns(avatar)
    stubs(:resized_image_url).with(avatar, width: 160, height: 160, format: :jpeg).returns("https://example.com/avatar.jpg")

    # Temporarily configure worker URL via ENV
    ENV.stubs(:[]).with("OG_WORKER_URL").returns("https://og.example.com/og")
    ENV.stubs(:[]).with("OG_SIGNING_SECRET").returns(nil)

    # Mock feature flag to be enabled
    stubs(:feature?).with(:dynamic_open_graph, blog: @blog).returns(true)

    result = open_graph_image_helper
    uri = URI.parse(result)
    params = CGI.parse(uri.query)

    assert_equal "https", uri.scheme
    assert_equal "og.example.com", uri.host
    assert_equal "/og", uri.path
    assert_equal [ "My Blog Post" ], params["title"]
    assert_equal [ "Joel's Blog" ], params["blogTitle"]
    assert_equal [ "https://example.com/avatar.jpg" ], params["avatar"]
  end

  private

    def open_graph_image_helper
      open_graph_image
    end
end
