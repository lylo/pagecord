require "test_helper"
require "open-uri"
require "mocha/minitest"

class Blog::ExportTest < ActiveSupport::TestCase
  setup do
    @blog = blogs(:joel)
  end

  def setup_post_with_image
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

  test "defaults to html format" do
    export = Blog::Export.create!(blog: @blog)
    assert export.html?
    assert_equal "HTML", export.display_format
  end

  test "can be created with markdown format" do
    export = Blog::Export.create!(blog: @blog, format: :markdown)
    assert export.markdown?
    assert_equal "Markdown", export.display_format
  end

  test "display_format returns proper format names" do
    html_export = Blog::Export.create!(blog: @blog, format: :html)
    markdown_export = Blog::Export.create!(blog: @blog, format: :markdown)

    assert_equal "HTML", html_export.display_format
    assert_equal "Markdown", markdown_export.display_format
  end

  test "creates a zip file with blog contents" do
    export = Blog::Export.create!(blog: @blog)
    export.perform

    assert export.file.attached?
    assert_equal "application/zip", export.file.content_type
    assert_match(/joel_export_\d+\.zip/, export.file.filename.to_s)
  end

  test "html export creates html files and index" do
    setup_post_with_image
    export = Blog::Export.create!(blog: @blog, format: :html)

    Dir.mktmpdir do |dir|
      export.send(:export_posts, dir)

      # Check HTML index exists
      index_file = File.join(dir, "index.html")
      assert File.exist?(index_file)
      index_content = File.read(index_file)
      assert_includes index_content, "<title>#{@blog.display_name}</title>"
      assert_includes index_content, "<a href=\"#{@post.slug}.html\">"

      # Check HTML post exists
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

  test "markdown export creates markdown files and index" do
    setup_post_with_image
    export = Blog::Export.create!(blog: @blog, format: :markdown)

    Dir.mktmpdir do |dir|
      export.send(:export_posts, dir)

      # Check Markdown index exists
      index_file = File.join(dir, "index.md")
      assert File.exist?(index_file)
      index_content = File.read(index_file)
      assert_includes index_content, "# #{@blog.display_name}"
      assert_includes index_content, "[#{@post.title}](#{@post.slug}.md)"

      # Check Markdown post exists
      md_file = File.join(dir, "#{@post.slug}.md")
      assert File.exist?(md_file)
      content = File.read(md_file)
      assert_includes content, "title: \"Test Post\""
      assert_includes content, "# Test Post"

      image_path = File.join(dir, "images", @post.token, "test_image.jpg")
      assert File.exist?(image_path)
      assert_equal @image_data, File.read(image_path)
      assert_includes content, "images/#{@post.token}/test_image.jpg"
    end
  end
end
