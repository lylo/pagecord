require "test_helper"

class PostsHelperTest < ActionView::TestCase
  test "without_action_text_image_wrapper preserves image captions" do
    html = <<~HTML
      <p>Check out this photo:</p>
      <action-text-attachment sgid="123">
        <figure class="attachment attachment--preview attachment--jpg">
          <img src="https://example.com/photo.jpg" alt="Uploaded image">
          <figcaption class="attachment__caption">A beautiful sunset</figcaption>
        </figure>
      </action-text-attachment>
    HTML

    result = without_action_text_image_wrapper(html)

    assert_includes result, "<figcaption"
    assert_includes result, "A beautiful sunset"
    assert_includes result, "<figure"
    assert_includes result, "<img"
    assert_not_includes result, "action-text-attachment"
  end

  test "without_action_text_image_wrapper preserves surrounding content" do
    html = <<~HTML
      <p>Before image</p>
      <action-text-attachment sgid="123">
        <figure class="attachment attachment--preview">
          <img src="https://example.com/photo.jpg" alt="Uploaded image">
        </figure>
      </action-text-attachment>
      <p>After image</p>
    HTML

    result = without_action_text_image_wrapper(html)

    assert_includes result, "Before image"
    assert_includes result, "After image"
    assert_includes result, "<figure"
    assert_not_includes result, "action-text-attachment"
  end
end
