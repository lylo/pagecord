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
      <br><img src=\"https://example.com/image.jpeg\"><br>
      </div>
    HTML
    assert_equal expected_html.strip, transformed_html
  end
end
