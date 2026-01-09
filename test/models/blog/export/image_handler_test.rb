require "test_helper"
require "mocha/minitest"

class Blog::Export::ImageHandlerTest < ActiveSupport::TestCase
  def setup
    @blog = blogs(:joel)
    @post = @blog.posts.new(title: "Test Post")
    @post.content = ActionText::Content.new(<<~HTML)
        <p>Here is an image:</p>
        <img src="http://example.com/test%20image.jpg" alt="Test">
      </div>
    HTML
    @post.save!

    @image_handler = Blog::Export::ImageHandler.new(@post, "tmp/images_dir")
  end

  test "replace image source with local path" do
    @image_handler.stubs(:download_image)
      .with("http://example.com/test%20image.jpg", regexp_matches(/test_image\.jpg$/))
      .returns(nil)

    processed_html = @image_handler.process_images(@post.content.body.to_s)

    assert_match %r{src="images/[^/]+/test_image\.jpg"}, processed_html
  end

  test "failed image download does not raise exception" do
    @image_handler.stubs(:download_image)
      .with("http://example.com/test%20image.jpg", regexp_matches(/test_image\.jpg$/))
      .raises(StandardError, "Download failed")

    Sentry.expects(:capture_exception)
      .with(instance_of(StandardError), has_entries(extra: has_entries(post_slug: @post.slug, image_src: "http://example.com/test%20image.jpg")))

    assert_nothing_raised do
      @image_handler.process_images(@post.content.body.to_s)
    end
  end

  test "extracts original URL from Cloudflare CDN image URLs" do
    cloudflare_url = "https://pagecord.com/cdn-cgi/image/width=1600,height=1200,format=webp,quality=90/https://storage.pagecord.com/78v1ct1yskcl66bzrl5zf8bz2rpw"
    original_url = "https://storage.pagecord.com/78v1ct1yskcl66bzrl5zf8bz2rpw"

    result = @image_handler.send(:extract_original_url, cloudflare_url)

    assert_equal original_url, result
  end

  test "leaves non-CDN URLs unchanged" do
    regular_url = "https://example.com/regular-image.jpg"

    result = @image_handler.send(:extract_original_url, regular_url)

    assert_equal regular_url, result
  end

  test "handles various CDN parameter formats" do
    # Test with different parameter combinations
    url_with_different_params = "https://pagecord.com/cdn-cgi/image/format=webp,quality=85,width=800/https://storage.pagecord.com/abc123"
    expected = "https://storage.pagecord.com/abc123"

    result = @image_handler.send(:extract_original_url, url_with_different_params)

    assert_equal expected, result
  end

  test "handles CDN URLs with query parameters in original URL" do
    url_with_query = "https://pagecord.com/cdn-cgi/image/width=1200/https://storage.pagecord.com/image123?v=2"
    expected = "https://storage.pagecord.com/image123?v=2"

    result = @image_handler.send(:extract_original_url, url_with_query)

    assert_equal expected, result
  end
end
