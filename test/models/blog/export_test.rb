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
      <div class="lexxy-content">
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

    # Mock the test image URL - use yields for block form of URI.open
    URI.expects(:open).with("http://example.com/test%20image.jpg", read_timeout: 30, redirect: true).yields(fake_image)

    # Mock any ActiveStorage URLs from fixtures (they'll have different URLs)
    URI.stubs(:open).with(regexp_matches(/rails\/active_storage/), read_timeout: 30, redirect: true).yields(StringIO.new("fixture image data"))
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

      image_path = File.join(dir, "images", @post.slug, "test_image.jpg")
      assert File.exist?(image_path)
      assert_equal @image_data, File.read(image_path)
      assert_includes content, "images/#{@post.slug}/test_image.jpg"
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

      image_path = File.join(dir, "images", @post.slug, "test_image.jpg")
      assert File.exist?(image_path)
      assert_equal @image_data, File.read(image_path)
      assert_includes content, "images/#{@post.slug}/test_image.jpg"
    end
  end

  test "markdown export preserves code block language" do
    post = @blog.posts.new(title: "Code Test")
    post.content = ActionText::Content.new(<<~HTML)
      <pre data-language="ruby" data-highlight-language="ruby">def hello
  puts "world"
end</pre>
    HTML
    post.save!

    export = Blog::Export.create!(blog: @blog, format: :markdown)

    Dir.mktmpdir do |dir|
      export.send(:export_posts, dir)

      md_file = File.join(dir, "#{post.slug}.md")
      assert File.exist?(md_file)
      content = File.read(md_file)

      # Check that the code fence includes the language
      assert_includes content, "```ruby"
      assert_includes content, "def hello"
      assert_includes content, 'puts "world"'
    end
  end
end
