require "test_helper"
require "mocha/minitest"

class OpenGraphHelperTest < ActionView::TestCase
  include OpenGraphHelper

  test "open_graph_image with first image" do
    @post = posts(:one)

    attachment = mock("attachment")
    @post.stubs(:first_image).returns(attachment)

    stubs(:resized_image_url).with(attachment, width: 1200, height: 630, crop: true).returns("https://example.com/resized-image.jpg")

    assert_equal "https://example.com/resized-image.jpg", open_graph_image
  end

  test "open_graph_image uses custom open_graph_image attachment when present" do
    @post = posts(:one)

    og_image = mock("og_image")
    og_image.stubs(:attached?).returns(true)
    @post.stubs(:open_graph_image).returns(og_image)

    stubs(:resized_image_url).with(og_image, width: 1200, height: 630, crop: true).returns("https://example.com/custom-og.jpg")

    assert_equal "https://example.com/custom-og.jpg", open_graph_image
  end

  test "open_graph_image falls back to first_image when no custom image attached" do
    @post = posts(:one)

    not_attached = mock("not_attached")
    not_attached.stubs(:attached?).returns(false)
    @post.stubs(:open_graph_image).returns(not_attached)

    content_image = mock("content_image")
    @post.stubs(:first_image).returns(content_image)

    stubs(:resized_image_url).with(content_image, width: 1200, height: 630, crop: true).returns("https://example.com/first-image.jpg")

    assert_equal "https://example.com/first-image.jpg", open_graph_image
  end

  test "open_graph_image returns dynamic image when suppressed, even with first image present" do
    with_og_env_vars do
      @post = posts(:one)
      @post.open_graph_image_suppressed = true

      attachment = mock("attachment")
      @post.stubs(:first_image).returns(attachment)

      result = open_graph_image

      assert_includes result, "https://og.example.com/og"
      assert_includes result, "The+Art+of+Street+Photography"
    end
  end

  test "open_graph_image returns dynamic image when suppressed, even with custom image attached" do
    with_og_env_vars do
      @post = posts(:one)
      @post.open_graph_image_suppressed = true

      attached = mock("attached")
      attached.stubs(:attached?).returns(true)
      @post.stubs(:open_graph_image).returns(attached)

      result = open_graph_image

      assert_includes result, "https://og.example.com/og"
    end
  end

  test "text-only post for subscribed account should have custom open graph image" do
    with_og_env_vars do
      @post = posts(:one)

      assert_equal "https://og.example.com/og?accentColor=%234fbd9c&avatar=http%3A%2F%2Ftest.host%2Fpagecord-mark-96.png&bgColor=%23ffffff&blogTitle=%40joel&textColor=%23334155&title=The+Art+of+Street+Photography", open_graph_image
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
