require "test_helper"
require "open-uri"
require "mocha/minitest"

class Blog::ExportTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)

    @post = @blog.posts.new(title: "Test Post")
    @post.content = ActionText::Content.new(<<~HTML)
      <div class="trix-content">
        <p>Here is an image:</p>
        <action-text-attachment sgid="123" content-type="image/jpeg" url="http://example.com/test%20image.jpg">
          <figure>
            <img src="http://example.com/test%20image.jpg" alt="Test">
          </figure>
        </action-text-attachment>
      </div>
      HTML
    @post.save!

    @image_data = "fake image data"
    fake_image = StringIO.new(@image_data)
    URI.expects(:open).with("http://example.com/test%20image.jpg").returns(fake_image)
  end

  test "creates a zip file with blog contents" do
    export = Blog::Export.create!(blog: @blog)
    export.perform

    assert export.file.attached?
    assert_equal "application/zip", export.file.content_type
    assert_match(/joel_export_\d+\.zip/, export.file.filename.to_s)
  end

  test "handles posts with images" do
    export = Blog::Export.create!(blog: @blog)

    Dir.mktmpdir do |dir|
      export.send(:export_posts, dir)

      html_file = File.join(dir, "#{@post.slug}.html")
      assert File.exist?(html_file)

      content = File.read(html_file)
      assert_includes content, "<title>Test Post</title>"
      assert_includes content, "<h1>Test Post</h1>"

      image_path = File.join(dir, "images", @post.token, "test_image.jpg")
      assert File.exist?(image_path)
      assert_equal @image_data, File.read(image_path)
      assert_includes content, "images/#{@post.token}/test_image.jpg"
    end
  end
end
