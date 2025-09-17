require "test_helper"

class PostsHelperTest < ActionView::TestCase
  include PostsHelper

  test "without_action_text_attachment_wrapper removes action-text-attachment wrapper and keeps figure element" do
    html_with_attachment = <<~HTML
    <div><p>hello, world!</p><action-text-attachment sgid="eyJfcmFpbHMiOnsiZGF0YSI6ImdpZDovL3BhZ2Vjb3JkL0FjdGl2ZVN0b3JhZ2U6OkJsb2IvMjU4P2V4cGlyZXNfaW4iLCJwdXIiOiJhdHRhY2hhYmxlIn19--ed0308c73550462b0ec79c35a88822899a914d61" content-type="image/jpeg" filename="IMG_4475.JPG" filesize="158121" width="652" height="1000" previewable="true"><figure class="attachment attachment--preview attachment--JPG"><img src="https://example.com/image.jpeg"></figure></action-text-attachment></div>
    HTML

    stripped_html = without_action_text_image_wrapper(html_with_attachment)

    expected_html = <<~HTML
    <div>
    <p>hello, world!</p>
    <figure class="attachment attachment--preview attachment--JPG"><img src="https://example.com/image.jpeg"></figure>
    </div>
    HTML

    assert_equal expected_html.strip, stripped_html.strip
  end

  test "strip_video_tags removes figure elements containing video tags" do
    html_with_video = <<~HTML
    <div>
      <p>Some text</p>
      <figure class="attachment attachment--preview attachment--mov">
        <video controls="controls" class="attachment__video max-h-[600px] mx-auto" src="http://example.com/video.mov"></video>
        <figcaption class="attachment__caption">A video</figcaption>
      </figure>
      <figure class="attachment attachment--preview attachment--JPG">
        <img src="https://example.com/image.jpeg">
      </figure>
      <p>More text</p>
    </div>
    HTML

    stripped_html = strip_video_tags(html_with_video)

    expected_html = <<~HTML
  <div>
    <p>Some text</p>
    <figure class="attachment attachment--preview attachment--JPG">
        <img src="https://example.com/image.jpeg">
      </figure>
      <p>More text</p>
    </div>
    HTML

    assert_equal flattened_html(expected_html), flattened_html(stripped_html)
  end

  test "social_link_url should return mailto link for email social link" do
    social_link = SocialLink.new(platform: "Email", url: "test@pagecord.com")
    assert_equal "mailto:test@pagecord.com", social_link_url(social_link)
  end

  test "social_link_url should return url for email social link if url starts with http" do
    social_link = SocialLink.new(platform: "Email", url: "https://pagecord.com")
    assert_equal "https://pagecord.com", social_link_url(social_link)
  end
end
