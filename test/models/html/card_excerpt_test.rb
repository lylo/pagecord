require "test_helper"

class Html::CardExcerptTest < ActiveSupport::TestCase
  test "keeps paragraphs and line breaks as plain text" do
    html = %(<h2>Pond</h2><p class="x"><em>An old</em> pond<br>a frog <a href="/x">jumps</a> in</p><ul><li>one</li><li>two</li></ul>)

    assert_equal "<p>Pond</p><p>An old pond<br>a frog jumps in</p><p>one</p><p>two</p>", Html::CardExcerpt.new.transform(html)
  end

  test "drops attachments, footnotes and scripts, and escapes text" do
    html = <<~HTML.delete("\n")
      <p>See this<sup data-footnote-ref="1"><a href="#fn-1">1</a></sup> &amp; that</p>
      <action-text-attachment sgid="abc" content-type="image/jpeg"></action-text-attachment>
      <script>alert(1)</script>
      <ol data-footnotes><li>The note.</li></ol>
    HTML

    assert_equal "<p>See this &amp; that</p>", Html::CardExcerpt.new.transform(html)
  end

  test "cuts at the limit and drops everything after" do
    html = "<p>The first paragraph is long enough.</p><p>The second is gone.</p>"

    assert_equal "<p>The first...</p>", Html::CardExcerpt.new(limit: 15).transform(html)
  end

  test "keeps short content whole under the limit" do
    html = "<p>Short.</p><p>Also short.</p>"

    assert_equal html, Html::CardExcerpt.new(limit: 324).transform(html)
  end
end
