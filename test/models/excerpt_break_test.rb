require "test_helper"

class ExcerptBreakTest < ActiveSupport::TestCase
  test "present? detects {{ more }}" do
    eb = ExcerptBreak.new("<p>Hello</p><p>{{ more }}</p><p>World</p>")
    assert eb.present?
  end

  test "present? detects {{ excerpt }}" do
    eb = ExcerptBreak.new("<p>Hello</p><p>{{ excerpt }}</p><p>World</p>")
    assert eb.present?
  end

  test "present? detects <!--more-->" do
    eb = ExcerptBreak.new("<p>Hello</p><!--more--><p>World</p>")
    assert eb.present?
  end

  test "present? detects escaped WordPress comment" do
    eb = ExcerptBreak.new("<p>Hello</p><p>&lt;!--more--&gt;</p><p>World</p>")
    assert eb.present?
  end

  test "present? is case-insensitive" do
    assert ExcerptBreak.new("<p>{{ MORE }}</p>").present?
    assert ExcerptBreak.new("<p>{{ More }}</p>").present?
    assert ExcerptBreak.new("<p>{{ EXCERPT }}</p>").present?
  end

  test "present? allows flexible whitespace" do
    assert ExcerptBreak.new("<p>{{more}}</p>").present?
    assert ExcerptBreak.new("<p>{{  more  }}</p>").present?
  end

  test "present? returns false when no marker" do
    assert_not ExcerptBreak.new("<p>Just a regular post</p>").present?
  end

  test "present? ignores markers inside code blocks" do
    html = "<pre><code>{{ more }}</code></pre><p>Content</p>"
    assert_not ExcerptBreak.new(html).present?
  end

  test "excerpt returns content before marker" do
    html = "<p>First paragraph</p><p>{{ more }}</p><p>Second paragraph</p>"
    result = ExcerptBreak.new(html).excerpt
    assert_includes result, "First paragraph"
    assert_not_includes result, "Second paragraph"
    assert_not_includes result, "{{ more }}"
  end

  test "excerpt works with <!--more-->" do
    html = "<p>Before</p><!--more--><p>After</p>"
    result = ExcerptBreak.new(html).excerpt
    assert_includes result, "Before"
    assert_not_includes result, "After"
  end

  test "excerpt returns full html when no marker present" do
    html = "<p>No marker here</p>"
    assert_equal html, ExcerptBreak.new(html).excerpt
  end

  test "strip removes marker but keeps all content" do
    html = "<p>Before</p><p>{{ more }}</p><p>After</p>"
    result = ExcerptBreak.new(html).strip
    assert_includes result, "Before"
    assert_includes result, "After"
    assert_not_includes result, "{{ more }}"
  end

  test "strip works with <!--more-->" do
    html = "<p>Before</p><!-- more --><p>After</p>"
    result = ExcerptBreak.new(html).strip
    assert_includes result, "Before"
    assert_includes result, "After"
    assert_not_includes result, "more"
  end

  test "strip returns full html when no marker present" do
    html = "<p>No marker here</p>"
    assert_equal html, ExcerptBreak.new(html).strip
  end

  test "excerpt_plain_text returns text before marker" do
    html = "<p>Hello world</p><p>{{ more }}</p><p>Hidden content</p>"
    result = ExcerptBreak.new(html).excerpt_plain_text
    assert_equal "Hello world", result
  end

  test "excerpt_plain_text returns empty string when no marker" do
    html = "<p>No marker</p>"
    assert_equal "", ExcerptBreak.new(html).excerpt_plain_text
  end

  test "only first marker is used for excerpt" do
    html = "<p>First</p><p>{{ more }}</p><p>Middle</p><p>{{ more }}</p><p>Last</p>"
    result = ExcerptBreak.new(html).excerpt
    assert_includes result, "First"
    assert_not_includes result, "Middle"
    assert_not_includes result, "Last"
  end

  test "marker inside code block is ignored for excerpt" do
    html = "<pre><code>{{ more }}</code></pre><p>Visible</p><p>{{ more }}</p><p>Hidden</p>"
    result = ExcerptBreak.new(html).excerpt
    assert_includes result, "Visible"
    assert_not_includes result, "Hidden"
  end
end
