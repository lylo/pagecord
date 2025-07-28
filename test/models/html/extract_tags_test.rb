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
    result = @transformer.transform(html)

    assert_equal [ "javascript", "rails", "ruby" ], @transformer.tags
  end

  test "should filter out invalid tag formats" do
    html = "Content here.\n\n#valid-tag #invalid! #another-valid #invalid@tag"
    result = @transformer.transform(html)

    assert_equal [ "another-valid", "valid-tag" ], @transformer.tags
  end

  test "should remove duplicate tags" do
    html = "Content here.\n\n#ruby #rails #ruby #javascript #rails"
    result = @transformer.transform(html)

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
    # Result should be empty or minimal after removing hashtags
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

    # Should preserve the original content and empty div but remove hashtag divs
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

    # Should only extract #tag2 since #tag1 is not at the end (there's "More content" after it)
    assert_equal [ "tag2" ], @transformer.tags
    assert_includes result, "Content"
    assert_includes result, "More content"
    assert_includes result, "#tag1" # This should remain since it's not at the end
    assert_not_includes result, "#tag2" # This should be removed
  end
end
