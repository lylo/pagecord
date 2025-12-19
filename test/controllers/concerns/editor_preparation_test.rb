require "test_helper"

class EditorPreparationTest < ActiveSupport::TestCase
  include EditorPreparation

  setup do
    @blog = blogs(:joel)
  end

  # Tests for content preparation (Lexxy)

  test "cleans Trix-created divs and converts to paragraphs" do
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

  test "removes trailing br tags and converts to paragraphs" do
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

  test "converts h1 to h2" do
    post = @blog.posts.create!(
      title: "Test Post",
      content: "<h1>Main Heading</h1><div>Content</div>"
    )

    prepare_content_for_editor(post)

    result = post.content.body.to_html
    assert_includes result, "<h2>Main Heading</h2>"
    assert_not_includes result, "<h1>"
  end

  test "preserves pre blocks when cleaning" do
    post = @blog.posts.create!(
      title: "Test Post",
      content: "<div>Text</div>\n\n<pre>Code\nLine 2</pre>\n\n<div>More</div>"
    )

    prepare_content_for_editor(post)

    assert_includes post.content.body.to_html, "<pre>Code\nLine 2</pre>"
  end

  test "preserves existing paragraphs" do
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

  test "removes whitespace between tags" do
    post = @blog.posts.create!(
      title: "Test Post",
      content: "<div>Content</div>  \n  <div>More</div>"
    )

    prepare_content_for_editor(post)

    assert_not post.content.body.to_html.include?(">  <")
  end

  test "handles nested divs from emails" do
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

  test "handles deeply nested divs" do
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

  test "handles mixed nested and non-nested divs" do
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
