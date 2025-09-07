require "test_helper"

class Html::SanitizeTest < ActiveSupport::TestCase
  test "should sanitize html" do
    html = <<~HTML
      <div><p>hello, world!</p><br><action-text-attachment content-type="image/jpeg" filename="IMG_4475.JPG" filesize="158121" width="652" height="1000" previewable="true"><figure class="attachment attachment--preview attachment--JPG"><img src="https://example.com/image.jpeg"></figure></action-text-attachment><br></div>
    HTML

    transformed_html = Html::Sanitize.new.transform(html)

    expected_html = <<~HTML
      <div>
      <p>hello, world!</p>
      <br><action-text-attachment content-type="image/jpeg" filename="IMG_4475.JPG"><figure><img src=\"https://example.com/image.jpeg\"></figure></action-text-attachment><br>
      </div>
    HTML
    assert_equal expected_html.strip, transformed_html
  end
end
