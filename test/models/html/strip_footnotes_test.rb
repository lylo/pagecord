require "test_helper"

class Html::StripFootnotesTest < ActiveSupport::TestCase
  test "removes markers and the note list" do
    html = <<~HTML
      <p>Some text<sup data-footnote-ref="1" id="fnref-1"><a href="#fn-1">1</a></sup>.</p>
      <ol data-footnotes><li id="fn-1"><p>The note.</p></li></ol>
    HTML

    result = Html::StripFootnotes.new.transform(html)

    assert_includes result, "<p>Some text.</p>"
    assert_not_includes result, "data-footnote-ref"
    assert_not_includes result, "data-footnotes"
    assert_not_includes result, "The note."
  end

  test "leaves ordinary superscripts and lists alone" do
    html = "<p>E = mc<sup>2</sup></p><ol><li>one</li></ol>"

    assert_equal html, Html::StripFootnotes.new.transform(html)
  end

  test "handles blank input" do
    assert_equal "", Html::StripFootnotes.new.transform("")
    assert_nil Html::StripFootnotes.new.transform(nil)
  end
end
