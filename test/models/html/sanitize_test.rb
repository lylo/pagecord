require "test_helper"

class Html::SanitizeTest < ActiveSupport::TestCase
  test "should sanitize html" do
    html = <<~HTML
      <div><p>hello, world!</p><br><figure class="attachment attachment--preview attachment--JPG"><img src="https://example.com/image.jpeg"></figure><br></div>
    HTML

    transformed_html = Html::Sanitize.new.transform(html)

    expected_html = <<~HTML
      <div>
      <p>hello, world!</p>
      <br><figure><img src=\"https://example.com/image.jpeg\"></figure><br>
      </div>
    HTML
    assert_equal expected_html.strip, transformed_html
  end

  test "preserves subscript and superscript" do
    html = "<div>H<sub>2</sub>O and x<sup>2</sup></div>"

    transformed_html = Html::Sanitize.new.transform(html)

    assert_includes transformed_html, "H<sub>2</sub>O"
    assert_includes transformed_html, "x<sup>2</sup>"
  end

  test "preserves collapsible details sections" do
    html = "<details open><summary>More</summary><p>Hidden detail.</p></details>"

    transformed_html = Html::Sanitize.new.transform(html)

    assert_includes transformed_html, "<details open"
    assert_includes transformed_html, "<summary>More</summary>"
    assert_includes transformed_html, "<p>Hidden detail.</p>"
  end

  test "strips inline styles" do
    html = <<~HTML
      <div class="align-right" style="font-size: 2em; text-align: right; color: red;">Right</div>
      <div style="font-family: ui-monospace, monospace;">Code-looking text</div>
    HTML

    transformed_html = Html::Sanitize.new.transform(html)

    assert_equal <<~HTML.strip, transformed_html
      <div>Right</div>
      <div>Code-looking text</div>
    HTML
  end
end
