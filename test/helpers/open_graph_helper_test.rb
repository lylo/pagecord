require "test_helper"
require "mocha/minitest"

class OpenGraphHelperTest < ActionView::TestCase
  include OpenGraphHelper

  test "open_graph_image with open graph image present" do
    @post = posts(:one)
    @post.open_graph_image = OpenGraphImage.new(url: "https://example.com/og-image.jpg")

    assert_equal "https://example.com/og-image.jpg", open_graph_image
  end

  test "open_graph_image with first image fallback" do
    @post = posts(:one)
    @post.stubs(:open_graph_image).returns(nil)

    # Mock an attachment as first image
    attachment = mock("attachment")
    @post.stubs(:first_image).returns(attachment)

    # Mock the resized_image_url helper
    stubs(:resized_image_url).with(attachment, width: 1200, height: 630, crop: true).returns("https://example.com/resized-image.jpg")

    assert_equal "https://example.com/resized-image.jpg", open_graph_image
  end

  test "text-only post for subscribed account should have custom open graph image" do
    with_og_env_vars do
      @post = posts(:one)

      assert_equal "https://og.example.com/og?accentColor=%234fbd9c&avatar=http%3A%2F%2Ftest.host%2Fapple-touch-icon.png&bgColor=%23ffffff&blogTitle=%40joel&textColor=%23334155&title=The+Art+of+Street+Photography", open_graph_image
    end
  end

  test "text-only post for free account should not have custom open graph image" do
    with_og_env_vars do
      @post = posts(:three)

      assert_nil open_graph_image
    end
end

  private

    def with_og_env_vars(&block)
      ENV["OG_WORKER_URL"] = "https://og.example.com/og"

      yield

      ENV["OG_WORKER_URL"] = nil
    end
end
