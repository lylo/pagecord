require "test_helper"

class Html::StripWhitespaceNodesTest < ActiveSupport::TestCase
  test "strips whitespace-only text nodes between block elements" do
    html = "<div>First paragraph</div>\n<div><br></div>\n<div>Second paragraph</div>"
    result = Html::StripWhitespaceNodes.new.transform(html)
    assert_equal "<div>First paragraph</div><div><br></div><div>Second paragraph</div>", result
  end

  test "preserves whitespace inside pre elements" do
    html = "<div>Before</div>\n<pre>line 1\nline 2</pre>\n<div>After</div>"
    result = Html::StripWhitespaceNodes.new.transform(html)
    assert_includes result, "line 1\nline 2"
  end

  test "preserves newlines inside block elements" do
    html = "<div>Hello.<br>\n</div><div>World.</div>"
    result = Html::StripWhitespaceNodes.new.transform(html)
    assert_includes result, "<br>\n</div>"
  end

  test "returns html unchanged when no whitespace nodes present" do
    html = "<div>First</div><div>Second</div>"
    result = Html::StripWhitespaceNodes.new.transform(html)
    assert_equal html, result
  end
end
