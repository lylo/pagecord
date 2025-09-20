require "test_helper"

class Html::StripParagraphsTest < ActiveSupport::TestCase
  test "should strip paragraphs and replace with breaks" do
    html = <<~HTML
      <p>hello, world!</p>
      <p>this is a test</p>
    HTML

    transformed_html = Html::StripParagraphs.new.transform(html)

    expected_html = <<~HTML
      <div>hello, world!<br><br>
      </div>
      <div>this is a test<br><br>
      </div>
    HTML
    assert_equal expected_html, transformed_html
  end
end
