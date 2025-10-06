require "test_helper"

class Html::LexxyCleanerTest < ActiveSupport::TestCase
  test "wraps simple text in paragraph" do
    input = "Hello world"
    expected = "<p>Hello world</p>"
    assert_equal expected, Html::LexxyCleaner.clean(input)
  end

  test "splits double br into separate paragraphs" do
    input = "First paragraph<br><br>Second paragraph"
    result = Html::LexxyCleaner.clean(input)

    assert_includes result, "<p>First paragraph</p>"
    assert_includes result, "<p>Second paragraph</p>"
  end

  test "preserves single br within paragraph" do
    input = "Line one<br>Line two"
    expected = "<p>Line one<br>Line two</p>"
    assert_equal expected, Html::LexxyCleaner.clean(input)
  end

  test "flattens nested div wrappers" do
    input = "<div><div><div>Content here</div></div></div>"
    expected = "<p>Content here</p>"
    assert_equal expected, Html::LexxyCleaner.clean(input)
  end

  test "preserves action-text-attachment as block element" do
    input = 'Text before<br><br><action-text-attachment sgid="123"></action-text-attachment><br><br>Text after'
    result = Html::LexxyCleaner.clean(input)

    assert_includes result, "<p>Text before</p>"
    assert_includes result, '<action-text-attachment sgid="123"></action-text-attachment>'
    assert_includes result, "<p>Text after</p>"
  end

  test "preserves figure elements" do
    input = "<div>Some text<br><br><figure><img src='test.jpg'></figure></div>"
    result = Html::LexxyCleaner.clean(input)

    assert_includes result, "<p>Some text</p>"
    assert_includes result, "<figure><img src=\"test.jpg\"></figure>"
  end

  test "preserves ul and ol lists" do
    input = "Text here<br><br><ul><li>Item 1</li><li>Item 2</li></ul>"
    result = Html::LexxyCleaner.clean(input)

    assert_includes result, "<p>Text here</p>"
    assert_includes result, "<ul>"
    assert_includes result, "<li>Item 1</li>"
    assert_includes result, "<li>Item 2</li>"
  end

  test "preserves blockquote" do
    input = "Introduction<br><br><blockquote>Quote text</blockquote><br><br>Conclusion"
    result = Html::LexxyCleaner.clean(input)

    assert_includes result, "<p>Introduction</p>"
    assert_includes result, "<blockquote>Quote text</blockquote>"
    assert_includes result, "<p>Conclusion</p>"
  end

  test "preserves pre and code blocks" do
    input = "Some code:<br><br><pre><code>def hello\n  puts 'hi'\nend</code></pre>"
    result = Html::LexxyCleaner.clean(input)

    assert_includes result, "<p>Some code:</p>"
    assert_includes result, "<pre><code>def hello"
  end

  test "preserves hr elements" do
    input = "Section 1<br><br><hr><br><br>Section 2"
    result = Html::LexxyCleaner.clean(input)

    assert_includes result, "<p>Section 1</p>"
    assert_includes result, "<hr>"
    assert_includes result, "<p>Section 2</p>"
  end

  test "preserves table elements" do
    input = "<table><tr><td>Cell</td></tr></table>Text after"
    result = Html::LexxyCleaner.clean(input)

    assert_includes result, "<table><tr><td>Cell</td></tr></table>"
    assert_includes result, "<p>Text after</p>"
  end

  test "handles mixed inline elements" do
    input = "Text with <strong>bold</strong> and <a href='#'>link</a><br><br>Next paragraph"
    result = Html::LexxyCleaner.clean(input)

    assert_includes result, "<p>Text with <strong>bold</strong> and <a href=\"#\">link</a></p>"
    assert_includes result, "<p>Next paragraph</p>"
  end

  test "removes empty paragraphs" do
    input = "<br><br><br><br>Content"
    expected = "<p>Content</p>"
    assert_equal expected, Html::LexxyCleaner.clean(input)
  end

  test "removes whitespace-only content" do
    input = "<div>   </div>"
    expected = ""
    assert_equal expected, Html::LexxyCleaner.clean(input)
  end

  test "removes trailing br elements from paragraphs" do
    input = "Text here<br>"
    expected = "<p>Text here</p>"
    assert_equal expected, Html::LexxyCleaner.clean(input)
  end

  test "handles complex nested structure from example" do
    input = <<~HTML
      <div>
        <div>
          <div>
            Some text here<br><br>More text
            <action-text-attachment sgid="123"></action-text-attachment><br><br>
            <ul><li>Item 1</li></ul>
          </div>
        </div>
      </div>
    HTML

    result = Html::LexxyCleaner.clean(input)

    assert_includes result, "Some text here"
    assert_includes result, "More text"
    assert_includes result, '<action-text-attachment sgid="123"></action-text-attachment>'
    assert_includes result, "<ul><li>Item 1</li></ul>"
    assert_includes result, "<p>"
    assert_includes result, "</p>"
  end

  test "handles multiple consecutive block elements" do
    input = "<h1>Title</h1><h2>Subtitle</h2><ul><li>Item</li></ul>"
    result = Html::LexxyCleaner.clean(input)

    assert_includes result, "<h2>Title</h2>"
    assert_includes result, "<h2>Subtitle</h2>"
    assert_includes result, "<ul><li>Item</li></ul>"
  end

  test "normalizes h1 to h2" do
    input = "<h1>Main Heading</h1>Content"
    result = Html::LexxyCleaner.clean(input)

    assert_includes result, "<h2>Main Heading</h2>"
    assert_not_includes result, "<h1>"
  end

  test "handles triple br sequences" do
    input = "Para 1<br><br><br>Para 2"
    result = Html::LexxyCleaner.clean(input)

    assert_includes result, "<p>Para 1</p>"
    assert_includes result, "<p>Para 2</p>"
  end

  test "returns empty string for empty input" do
    assert_equal "", Html::LexxyCleaner.clean("")
  end

  test "returns empty string for only divs and whitespace" do
    input = "<div><div>   </div></div>"
    assert_equal "", Html::LexxyCleaner.clean(input)
  end

  test "handles span and other inline elements" do
    input = "<span style='color: red'>Red text</span> and normal text"
    expected = "<p><span style=\"color: red\">Red text</span> and normal text</p>"
    assert_equal expected, Html::LexxyCleaner.clean(input)
  end

  test "preserves nested inline elements within paragraphs" do
    input = "<em>Italic <strong>and bold</strong></em><br><br>Next"
    result = Html::LexxyCleaner.clean(input)

    assert_includes result, "<p><em>Italic <strong>and bold</strong></em></p>"
    assert_includes result, "<p>Next</p>"
  end

  test "handles content with only br tags" do
    input = "<br><br><br>"
    assert_equal "", Html::LexxyCleaner.clean(input)
  end

  test "handles deeply nested divs with only whitespace" do
    input = "<div><div><div>   </div></div></div>"
    assert_equal "", Html::LexxyCleaner.clean(input)
  end

  test "handles divs with only br tags" do
    input = "<div><br></div><div><br><br></div>"
    assert_equal "", Html::LexxyCleaner.clean(input)
  end
end
