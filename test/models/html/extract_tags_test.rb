require "test_helper"

class Html::ExtractTagsTest < ActiveSupport::TestCase
  def setup
    @transformer = Html::ExtractTags.new
  end

  test "should extract hashtags from plain text at end of content" do
    html = "This is a post about programming.\n\n#ruby #rails #programming"
    result = @transformer.transform(html)

    assert_equal [ "programming", "rails", "ruby" ], @transformer.tags
    assert_not_includes result, "#ruby"
    assert_not_includes result, "#rails"
    assert_not_includes result, "#programming"
    assert_includes result, "This is a post about programming."
  end

  test "should extract hashtags from HTML content" do
    html = "<p>This is a post about web development.</p><p>#javascript #html #css</p>"
    result = @transformer.transform(html)

    assert_equal [ "css", "html", "javascript" ], @transformer.tags
    assert_not_includes result, "#javascript"
    assert_not_includes result, "#html"
    assert_not_includes result, "#css"
    assert_includes result, "This is a post about web development."
  end

  test "should handle content without hashtags" do
    html = "This is a regular post without any hashtags."
    result = @transformer.transform(html)

    assert_equal [], @transformer.tags
    assert_equal html, result
  end

  test "should ignore hashtags in the middle of content" do
    html = "I was working on #ruby today.\n\nLater I switched to other things.\n\n#programming #coding"
    result = @transformer.transform(html)

    assert_equal [ "coding", "programming" ], @transformer.tags
    assert_includes result, "#ruby today"  # This hashtag should remain
    assert_not_includes result, "#programming"  # These should be removed
    assert_not_includes result, "#coding"
  end

  test "should handle multiple lines of hashtags at the end" do
    html = "Here's my post content.\n\n#first #second\n#third #fourth"
    result = @transformer.transform(html)

    assert_equal [ "first", "fourth", "second", "third" ], @transformer.tags
    assert_not_includes result, "#first"
    assert_not_includes result, "#second"
    assert_not_includes result, "#third"
    assert_not_includes result, "#fourth"
    assert_includes result, "Here's my post content."
  end

  test "should normalize tag case and sort tags" do
    html = "Content here.\n\n#Ruby #RAILS #javascript"
    @transformer.transform(html)

    assert_equal [ "javascript", "rails", "ruby" ], @transformer.tags
  end

  test "should filter out invalid tag formats" do
    html = "Content here.\n\n#valid-tag #another-valid"
    @transformer.transform(html)

    assert_equal [ "another-valid", "valid-tag" ], @transformer.tags

    transformer = Html::ExtractTags.new
    html_mixed = "Content here.\n\n#valid-tag #invalid! #another-valid #invalid@tag"
    transformer.transform(html_mixed)
    assert_equal [ "another-valid", "valid-tag" ], transformer.tags
  end

  test "should remove duplicate tags" do
    html = "Content here.\n\n#ruby #rails #ruby #javascript #rails"
    @transformer.transform(html)

    assert_equal [ "javascript", "rails", "ruby" ], @transformer.tags
  end

  test "should handle empty content" do
    html = ""
    @transformer.transform(html)

    assert_equal [], @transformer.tags
  end

  test "should handle content with only hashtags" do
    html = "#ruby #rails #programming"
    result = @transformer.transform(html)

    assert_equal [ "programming", "rails", "ruby" ], @transformer.tags
    assert result.strip.empty? || result.strip == "<br>" || result.strip == "<p></p>"
  end

  test "should handle hashtags with empty lines at the end" do
    html = "Here's my content.\n\n\n#tag1 #tag2\n\n"
    result = @transformer.transform(html)

    assert_equal [ "tag1", "tag2" ], @transformer.tags
    assert_includes result, "Here's my content."
    assert_not_includes result, "#tag1"
    assert_not_includes result, "#tag2"
  end

  test "should extract hashtags from multiple consecutive HTML elements" do
    html = "<div>This is a test</div><div><br></div><div>#test #rails</div><div>#programming</div><div><br></div>"
    result = @transformer.transform(html)

    assert_equal [ "programming", "rails", "test" ], @transformer.tags
    assert_includes result, "This is a test"
    assert_not_includes result, "#test"
    assert_not_includes result, "#rails"
    assert_not_includes result, "#programming"

    assert_includes result, "<div>This is a test</div>"
    assert_includes result, "<div><br></div>"
  end

  test "should handle mixed content and hashtag elements" do
    html = "<p>Regular content</p><p>More content</p><p>#tag1 #tag2</p><p>#tag3</p>"
    result = @transformer.transform(html)

    assert_equal [ "tag1", "tag2", "tag3" ], @transformer.tags
    assert_includes result, "Regular content"
    assert_includes result, "More content"
    assert_not_includes result, "#tag1"
    assert_not_includes result, "#tag2"
    assert_not_includes result, "#tag3"
  end

  test "should stop at first non-hashtag element when working backwards" do
    html = "<div>Content</div><div>#tag1</div><div>More content</div><div>#tag2</div>"
    result = @transformer.transform(html)

    assert_equal [ "tag2" ], @transformer.tags
    assert_includes result, "Content"
    assert_includes result, "More content"
    assert_includes result, "#tag1"
    assert_not_includes result, "#tag2"
  end

  test "should extract hashtags mixed with content in same element" do
    html = "<div>This is content with hashtags at the end<br><br>#test #rails<br>#programming</div>"
    result = @transformer.transform(html)

    assert_equal [ "programming", "rails", "test" ], @transformer.tags
    assert_includes result, "This is content with hashtags at the end"
    assert_not_includes result, "#test"
    assert_not_includes result, "#rails"
    assert_not_includes result, "#programming"
  end

  test "should handle hashtags without spaces between them" do
    html = "<div>Some content</div><div>#tag1#tag2 #tag3</div>"
    result = @transformer.transform(html)

    assert_equal [ "tag1", "tag2", "tag3" ], @transformer.tags
    assert_includes result, "Some content"
    assert_not_includes result, "#tag1"
    assert_not_includes result, "#tag2"
    assert_not_includes result, "#tag3"
  end

  test "should extract valid hashtags from lines with mixed valid and invalid formats" do
    html = "Content here.\n\n#ruby #rails! #javascript #invalid@tag #python"
    result = @transformer.transform(html)

    assert_equal [ "javascript", "python", "ruby" ], @transformer.tags

    assert_not_includes result, "#ruby"
    assert_not_includes result, "#javascript"
    assert_not_includes result, "#python"

    assert_includes result, "Content here"
    assert_includes result, "#rails!"
    assert_includes result, "#invalid@tag"
  end

  test "should not extract hashtags when mixed with non-hashtag content" do
    html = "Content here.\n\nCheck this out #ruby #rails"
    result = @transformer.transform(html)

    assert_equal [], @transformer.tags
    assert_equal html, result
  end

  test "should handle edge cases with hashtag-like patterns" do
    transformer = Html::ExtractTags.new
    html1 = "Content here.\n\n#valid #123valid #another-valid #@symbol"
    transformer.transform(html1)
    assert_equal [ "123valid", "another-valid", "valid" ], transformer.tags

    html2 = "Content here.\n\n#invalid! #@symbol #$money"
    transformer.transform(html2)
    assert_equal [], transformer.tags
  end

  test "should extract hashtags followed by non-breaking space" do
    nbsp = "\u00A0"
    html = "This is a post about Pagecord.\n\n#pagecord#{nbsp}#rails#{nbsp}#ruby#{nbsp}"
    result = @transformer.transform(html)

    assert_equal [ "pagecord", "rails", "ruby" ], @transformer.tags
    assert_not_includes result, "#pagecord"
    assert_not_includes result, "#rails"
    assert_not_includes result, "#ruby"
    assert_includes result, "This is a post about Pagecord."
  end

  test "should extract hashtags followed by HTML elements containing only nbsp" do
    # This simulates Apple Mail output where tags are followed by <div>&nbsp;</div>
    html = "<div>Safari password autofill issue.</div><div>#software #web</div><div>&nbsp;</div><div><br></div>"
    result = @transformer.transform(html)

    assert_equal [ "software", "web" ], @transformer.tags
    assert_not_includes result, "#software"
    assert_not_includes result, "#web"
    assert_includes result, "Safari password autofill issue."
  end
end
