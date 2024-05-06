require "test_helper"

class PostsHelperTest < ActionView::TestCase
  include PostsHelper

  test "without_action_text_attachment_wrapper removes action-text-attachment wrapper and keeps img tag" do
    html_with_attachment = <<~HTML
    <div><p>hello, world!</p><action-text-attachment sgid="eyJfcmFpbHMiOnsiZGF0YSI6ImdpZDovL3BhZ2Vjb3JkL0FjdGl2ZVN0b3JhZ2U6OkJsb2IvMjU4P2V4cGlyZXNfaW4iLCJwdXIiOiJhdHRhY2hhYmxlIn19--ed0308c73550462b0ec79c35a88822899a914d61" content-type="image/jpeg" filename="IMG_4475.JPG" filesize="158121" width="652" height="1000" previewable="true"><figure class="attachment attachment--preview attachment--JPG"><img src="https://example.com/image.jpeg"></figure></action-text-attachment></div>
    HTML

    stripped_html = without_action_text_image_wrapper(html_with_attachment)

    expected_html = <<~HTML
    <div><p>hello, world!</p><img src="https://example.com/image.jpeg"></div>
    HTML

    assert_equal expected_html, stripped_html
  end
end