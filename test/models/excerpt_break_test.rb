require "test_helper"

class ExcerptBreakTest < ActiveSupport::TestCase
  # .extract — returns HTML before the marker, or nil

  test "extract returns HTML before {{ more }}" do
    html = "<p>First</p><p>{{ more }}</p><p>Second</p>"
    result = ExcerptBreak.extract(html)
    assert_includes result, "First"
    assert_not_includes result, "Second"
    assert_not_includes result, "{{ more }}"
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

  test "extract returns HTML before escaped WordPress comment" do
    result = ExcerptBreak.extract("<p>Before</p><p>&lt;!--more--&gt;</p><p>After</p>")
    assert_includes result, "Before"
    assert_not_includes result, "After"
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

  test "extract ignores markers inside code blocks" do
    html = "<pre><code>{{ more }}</code></pre><p>Visible</p><p>{{ more }}</p><p>Hidden</p>"
    result = ExcerptBreak.extract(html)
    assert_includes result, "Visible"
    assert_not_includes result, "Hidden"
  end

  test "extract only uses first marker" do
    html = "<p>First</p><p>{{ more }}</p><p>Middle</p><p>{{ more }}</p><p>Last</p>"
    result = ExcerptBreak.extract(html)
    assert_includes result, "First"
    assert_not_includes result, "Middle"
  end

  # .strip — removes marker paragraph, keeps all content

  test "strip removes {{ more }} paragraph" do
    html = "<p>Before</p><p>{{ more }}</p><p>After</p>"
    result = ExcerptBreak.strip(html)
    assert_includes result, "Before"
    assert_includes result, "After"
    assert_not_includes result, "{{ more }}"
  end

  test "strip removes <!--more--> comment" do
    html = "<p>Before</p><!-- more --><p>After</p>"
    result = ExcerptBreak.strip(html)
    assert_includes result, "Before"
    assert_includes result, "After"
  end

  test "strip removes escaped WordPress comment" do
    html = "<p>Before</p><p>&lt;!--more--&gt;</p><p>After</p>"
    result = ExcerptBreak.strip(html)
    assert_includes result, "Before"
    assert_includes result, "After"
    assert_not_includes result, "&lt;!--more--&gt;"
  end

  test "strip returns html unchanged when no marker" do
    html = "<p>No marker</p>"
    assert_equal html, ExcerptBreak.strip(html)
  end
end
