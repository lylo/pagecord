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

  test "failed image download" do
    @image_handler.stubs(:download_image)
      .with("http://example.com/test%20image.jpg", regexp_matches(/test_image\.jpg$/))
      .raises(StandardError, "Download failed")

    Sentry.expects(:capture_message)
      .with(regexp_matches(/Unable to process image.*Download failed/))

    processed_html = @image_handler.process_images(@post.content.body.to_s)

    # The HTML should still be processed even with failed image download
    assert_not_nil processed_html
  end
end
