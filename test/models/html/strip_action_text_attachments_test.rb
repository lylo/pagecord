require "test_helper"

class Html::StripActionTextAttachmentsTest < ActiveSupport::TestCase
  test "should strip action-text-attachment" do
    html = <<~HTML
      <div>
      Hello, World
      <br>
      <action-text-attachment sgid="123">
        <figure>
          <img src="image.jpg" alt="Sample Image">
        </figure>
      </action-text-attachment>
      </div>
    HTML
    expected_html = <<~HTML
      <div>
      Hello, World
      <br>
      <img src="image.jpg" alt="Sample Image">
      </div>
    HTML
    result = Html::StripActionTextAttachments.new.transform(html)
    assert_equal expected_html, result
  end
end
