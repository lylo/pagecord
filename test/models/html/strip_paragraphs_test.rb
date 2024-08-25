require "test_helper"

class Html::StripParagraphsTest < ActiveSupport::TestCase

  test "should strip paragraphs and replace with breaks" do
    html = <<~HTML
      <p>hello, world!</p>
      <p>this is a test</p>
    HTML

    transformed_html = Html::StripParagraphs.new.transform(html)

    expected_html = <<~HTML
      hello, world!<br><br>
      this is a test<br><br>
    HTML
    assert_equal expected_html, transformed_html
  end
end
