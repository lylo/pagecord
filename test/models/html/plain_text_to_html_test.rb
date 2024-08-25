require "test_helper"

class Html::PlainTextToHtmlTest < ActiveSupport::TestCase

  test "should convert plain text to html" do
    plain_text = <<~TEXT
      hello, world!

      this is a test
    TEXT

    html = Html::PlainTextToHtml.new.transform(plain_text)

    expected_html = <<~HTML
      hello, world!<br><br>this is a test<br>
    HTML
    assert_equal expected_html.strip, html
  end
end
