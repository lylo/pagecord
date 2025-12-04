require "test_helper"
require "mocha/minitest"

class OpenGraphHelperTest < ActionView::TestCase
  include OpenGraphHelper

  def teardown
    ENV.delete("OG_WORKER_URL")
    ENV.delete("OG_SIGNING_SECRET")
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

  test "open_graph_image with no post and no dynamic OG returns nil" do
    @post = nil
    @blog = blogs(:joel)
    # Feature not enabled, so should return nil
    @blog.features = []
    @blog.save!
    assert_nil open_graph_image_helper
  end

  test "open_graph_image for blog home page with dynamic OG" do
    @post = nil
    @blog = blogs(:joel)
    @blog.subdomain = "jason"
    @blog.stubs(:display_name).returns("Jason Journals")
    @blog.stubs(:custom_domain).returns(nil)
    @blog.stubs(:avatar).returns(stub(attached?: false))

    # Enable the dynamic_open_graph feature
    @blog.features = [ "dynamic_open_graph" ]
    @blog.save!

    # Temporarily configure worker URL via ENV
    ENV["OG_WORKER_URL"] = "https://og.example.com/og"
    ENV["OG_SIGNING_SECRET"] = nil

    # Mock request for default favicon URL
    stubs(:request).returns(stub(protocol: "http://", host_with_port: "example.com:3000"))

    result = open_graph_image_helper
    uri = URI.parse(result)
    params = CGI.parse(uri.query)

    assert_equal "https", uri.scheme
    assert_equal "og.example.com", uri.host
    assert_equal "/og", uri.path
    assert_equal [ "Jason Journals" ], params["title"]
    assert_equal [ "jason.pagecord.com" ], params["blogTitle"]
    assert_equal [ "http://example.com:3000/apple-touch-icon.png" ], params["avatar"]
  end

  test "open_graph_image with dynamic OG worker URL configured" do
    @post = posts(:one)
    @post.stubs(:open_graph_image).returns(nil)
    @post.stubs(:first_image).returns(nil)
    @post.stubs(:display_title).returns("My Blog Post")
    @blog = @post.blog
    @blog.stubs(:display_name).returns("Joel's Blog")
    @blog.stubs(:avatar).returns(stub(attached?: false))

    # Enable the dynamic_open_graph feature
    @blog.features = [ "dynamic_open_graph" ]
    @blog.save!

    # Temporarily configure worker URL via ENV
    ENV["OG_WORKER_URL"] = "https://og.example.com/og"
    ENV["OG_SIGNING_SECRET"] = nil

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

    # Ensure the feature is NOT enabled
    @blog.features = []
    @blog.save!

    result = open_graph_image_helper
    assert_nil result
  end

  test "open_graph_image with dynamic OG worker URL and avatar" do
    @post = posts(:one)
    @post.stubs(:open_graph_image).returns(nil)
    @post.stubs(:first_image).returns(nil)
    @post.stubs(:display_title).returns("My Blog Post")
    @blog = @post.blog
    @blog.stubs(:display_name).returns("Joel's Blog")

    # Enable the dynamic_open_graph feature
    @blog.features = [ "dynamic_open_graph" ]
    @blog.save!

    # Mock avatar and :thumb variant
    avatar = mock("avatar")
    avatar.stubs(:attached?).returns(true)
    thumb_variant = mock("thumb_variant")
    avatar.stubs(:variant).with(:thumb).returns(thumb_variant)
    @blog.stubs(:avatar).returns(avatar)
    stubs(:rails_public_blob_url).with(thumb_variant).returns("https://example.com/avatar.jpg")

    # Temporarily configure worker URL via ENV
    ENV["OG_WORKER_URL"] = "https://og.example.com/og"
    ENV["OG_SIGNING_SECRET"] = nil

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

    def current_features
      Rails.features.for(blog: @blog)
    end
end
