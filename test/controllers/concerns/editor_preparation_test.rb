require "test_helper"

class EditorPreparationTest < ActiveSupport::TestCase
  include EditorPreparation

  setup do
    @blog = blogs(:joel)
  end

  def current_features
    Rails.features.for(blog: @blog)
  end

  # Tests for Trix editor (when blog.features = [])

  test "converts paragraphs to divs with double br for Trix" do
    @blog.update!(features: [])

    post = @blog.posts.create!(
      title: "Test Post",
      content: "<p>First paragraph</p><p>Second paragraph</p>"
    )

    prepare_content_for_editor(post)

    result = post.content.body.to_html
    assert_includes result, "<div>First paragraph<br><br>"
    assert_includes result, "<div>Second paragraph<br><br>"
    assert_not_includes result, "<p>"
  end

  test "converts h2, h3, h4 to h1 for Trix" do
    @blog.update!(features: [])

    post = @blog.posts.create!(
      title: "Test Post",
      content: "<h2>Heading 2</h2><h3>Heading 3</h3><h4>Heading 4</h4>"
    )

    prepare_content_for_editor(post)

    assert_includes post.content.body.to_html, "<h1>Heading 2</h1>"
    assert_includes post.content.body.to_html, "<h1>Heading 3</h1>"
    assert_includes post.content.body.to_html, "<h1>Heading 4</h1>"
  end

  test "preserves pre blocks for Trix" do
    @blog.update!(features: [])

    post = @blog.posts.create!(
      title: "Test Post",
      content: "<p>Line 1\nLine 2</p><pre>Code\nLine 2</pre>"
    )

    prepare_content_for_editor(post)

    result = post.content.body.to_html
    # Pre blocks should be preserved
    assert_includes result, "<pre>Code\nLine 2</pre>"
    # Paragraphs should be converted to divs
    assert_includes result, "<div>"
  end

  test "converts multiple paragraphs for Trix" do
    @blog.update!(features: [])

    post = @blog.posts.create!(
      title: "Test Post",
      content: "<p>Content</p><p>More content</p>"
    )

    prepare_content_for_editor(post)

    result = post.content.body.to_html
    assert_includes result, "<div>Content<br><br>"
    assert_includes result, "<div>More content<br><br>"
  end

  test "does not modify content without paragraphs for Trix" do
    @blog.update!(features: [])

    post = @blog.posts.create!(
      title: "Test Post",
      content: "<div>Already formatted</div>"
    )

    prepare_content_for_editor(post)

    assert_equal "<div>Already formatted</div>", post.content.body.to_html
  end

  # Tests for Lexxy editor (when blog.features = ["lexxy"])

  test "cleans Trix-created divs and converts to paragraphs for Lexxy" do
    @blog.update!(features: [ "lexxy" ])

    # This is typical Trix output - divs with br tags
    post = @blog.posts.create!(
      title: "Test Post",
      content: "<div><br>First line</div><div><br>Second line</div><div><br><br></div>"
    )

    prepare_content_for_editor(post)

    # Should remove leading <br> tags, empty divs, and convert to paragraphs
    result = post.content.body.to_html
    assert_includes result, "<p>First line</p>"
    assert_includes result, "<p>Second line</p>"
    assert_not_includes result, "<div><br>"
    assert_not_includes result, "<div><br><br></div>"
    assert_not_includes result, "<div>"
  end

  test "removes trailing br tags and converts to paragraphs for Lexxy" do
    @blog.update!(features: [ "lexxy" ])

    post = @blog.posts.create!(
      title: "Test Post",
      content: "<div>Content<br><br></div><div>More content<br></div>"
    )

    prepare_content_for_editor(post)

    result = post.content.body.to_html
    # Trailing <br> tags should be removed and divs should become paragraphs
    assert_includes result, "<p>Content</p>"
    assert_includes result, "<p>More content</p>"
    assert_not_includes result, "<br>"
    assert_not_includes result, "<div>"
  end

  test "converts h1 to h2 for Lexxy" do
    @blog.update!(features: [ "lexxy" ])

    post = @blog.posts.create!(
      title: "Test Post",
      content: "<h1>Main Heading</h1><div>Content</div>"
    )

    prepare_content_for_editor(post)

    result = post.content.body.to_html
    assert_includes result, "<h2>Main Heading</h2>"
    assert_not_includes result, "<h1>"
  end

  test "preserves pre blocks when cleaning for Lexxy" do
    @blog.update!(features: [ "lexxy" ])

    post = @blog.posts.create!(
      title: "Test Post",
      content: "<div>Text</div>\n\n<pre>Code\nLine 2</pre>\n\n<div>More</div>"
    )

    prepare_content_for_editor(post)

    assert_includes post.content.body.to_html, "<pre>Code\nLine 2</pre>"
  end

  test "preserves existing paragraphs for Lexxy" do
    @blog.update!(features: [ "lexxy" ])

    # Content with paragraphs should be preserved
    post = @blog.posts.create!(
      title: "Test Post",
      content: "<p>Paragraph content</p><p>More content</p>"
    )

    prepare_content_for_editor(post)

    result = post.content.body.to_html
    assert_includes result, "<p>Paragraph content</p>"
    assert_includes result, "<p>More content</p>"
  end

  test "removes whitespace between tags for Lexxy" do
    @blog.update!(features: [ "lexxy" ])

    post = @blog.posts.create!(
      title: "Test Post",
      content: "<div>Content</div>  \n  <div>More</div>"
    )

    prepare_content_for_editor(post)

    assert_not post.content.body.to_html.include?(">  <")
  end

  test "handles nested divs from emails for Lexxy" do
    @blog.update!(features: [ "lexxy" ])

    # Typical email structure with wrapper divs
    post = @blog.posts.create!(
      title: "Test Post",
      content: "<div><div>First paragraph</div><div>Second paragraph</div></div>"
    )

    prepare_content_for_editor(post)

    result = post.content.body.to_html
    # Inner divs should become paragraphs, wrapper div should be removed
    assert_includes result, "<p>First paragraph</p>"
    assert_includes result, "<p>Second paragraph</p>"
    # Should not have nested paragraphs
    assert_not_includes result, "<p><p>"
  end

  test "handles deeply nested divs for Lexxy" do
    @blog.update!(features: [ "lexxy" ])

    post = @blog.posts.create!(
      title: "Test Post",
      content: "<div><div><div>Content</div></div></div>"
    )

    prepare_content_for_editor(post)

    result = post.content.body.to_html
    # Innermost div should become paragraph, wrappers removed
    assert_includes result, "<p>Content</p>"
    assert_not_includes result, "<div>"
  end

  test "handles mixed nested and non-nested divs for Lexxy" do
    @blog.update!(features: [ "lexxy" ])

    post = @blog.posts.create!(
      title: "Test Post",
      content: "<div>Standalone</div><div><div>Nested content</div></div>"
    )

    prepare_content_for_editor(post)

    result = post.content.body.to_html
    assert_includes result, "<p>Standalone</p>"
    assert_includes result, "<p>Nested content</p>"
  end

  # General tests

  test "does nothing for blank content" do
    post = posts(:joel_draft)

    # Temporarily remove the original content
    original_content = post.content.to_s
    post.content.body = nil

    assert_nothing_raised do
      prepare_content_for_editor(post)
    end

    # Ensure content is still nil
    assert_nil post.content.body&.to_html
  end
end
