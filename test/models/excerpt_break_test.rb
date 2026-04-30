require "test_helper"

class ExcerptBreakTest < ActiveSupport::TestCase
  # .extract

  test "extract returns HTML before {{ more }}" do
    result = ExcerptBreak.extract("<p>First</p><p>{{ more }}</p><p>Second</p>")
    assert_includes result, "First"
    assert_not_includes result, "Second"
  end

  test "extract returns HTML before {{ excerpt }}" do
    result = ExcerptBreak.extract("<p>Visible</p><p>{{ excerpt }}</p><p>Hidden</p>")
    assert_includes result, "Visible"
    assert_not_includes result, "Hidden"
  end

  test "extract returns HTML before <!--more-->" do
    result = ExcerptBreak.extract("<p>Before</p><!--more--><p>After</p>")
    assert_includes result, "Before"
    assert_not_includes result, "After"
  end

  test "extract handles escaped WordPress comment (decoded by Nokogiri)" do
    result = ExcerptBreak.extract("<p>Before</p><p>&lt;!--more--&gt;</p><p>After</p>")
    assert_includes result, "Before"
    assert_not_includes result, "After"
  end

  test "extract works with div-wrapped content" do
    result = ExcerptBreak.extract("<div>Intro</div><div>{{ more }}</div><div>Rest</div>")
    assert_includes result, "Intro"
    assert_not_includes result, "Rest"
  end

  test "extract returns nil when no marker" do
    assert_nil ExcerptBreak.extract("<p>No marker here</p>")
  end

  test "extract is case-insensitive" do
    assert ExcerptBreak.extract("<p>A</p><p>{{ MORE }}</p><p>B</p>")
    assert ExcerptBreak.extract("<p>A</p><p>{{ Excerpt }}</p><p>B</p>")
  end

  test "extract allows flexible whitespace" do
    assert ExcerptBreak.extract("<p>A</p><p>{{more}}</p><p>B</p>")
    assert ExcerptBreak.extract("<p>A</p><p>{{  more  }}</p><p>B</p>")
  end

  test "extract only uses first marker" do
    result = ExcerptBreak.extract("<p>First</p><p>{{ more }}</p><p>Middle</p><p>{{ more }}</p><p>Last</p>")
    assert_includes result, "First"
    assert_not_includes result, "Middle"
  end

  test "extract ignores markers nested inside lists" do
    assert_nil ExcerptBreak.extract("<ul><li>{{ more }}</li></ul><p>Content</p>")
  end

  test "extract ignores markers nested inside blockquotes" do
    assert_nil ExcerptBreak.extract("<blockquote><p>{{ more }}</p></blockquote><p>Content</p>")
  end

  test "extract ignores markers mixed with other text" do
    assert_nil ExcerptBreak.extract("<p>Some text {{ more }} more text</p>")
  end

  # .strip

  test "strip removes {{ more }} paragraph and keeps all content" do
    result = ExcerptBreak.strip("<p>Before</p><p>{{ more }}</p><p>After</p>")
    assert_includes result, "Before"
    assert_includes result, "After"
    assert_not_includes result, "{{ more }}"
  end

  test "strip removes <!--more--> comment" do
    result = ExcerptBreak.strip("<p>Before</p><!-- more --><p>After</p>")
    assert_includes result, "Before"
    assert_includes result, "After"
  end

  test "strip works with div-wrapped content" do
    result = ExcerptBreak.strip("<div>Before</div><div>{{ more }}</div><div>After</div>")
    assert_includes result, "Before"
    assert_includes result, "After"
    assert_not_includes result, "{{ more }}"
  end

  test "strip removes escaped WordPress comment" do
    result = ExcerptBreak.strip("<p>Before</p><p>&lt;!--more--&gt;</p><p>After</p>")
    assert_includes result, "Before"
    assert_includes result, "After"
  end

  test "strip returns html unchanged when no marker" do
    html = "<p>No marker</p>"
    assert_equal html, ExcerptBreak.strip(html)
  end

  test "strip ignores markers nested inside lists" do
    html = "<ul><li>{{ more }}</li></ul><p>Content</p>"
    assert_equal html, ExcerptBreak.strip(html)
  end
end
