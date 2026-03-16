require "test_helper"

class Html::StripGalleryAttachmentChildrenTest < ActiveSupport::TestCase
  test "strips figure children from gallery attachments" do
    input = '<div class="attachment-gallery attachment-gallery--2"><action-text-attachment sgid="1" presentation="gallery"><figure class="attachment"><img src="photo.jpg"></figure></action-text-attachment><action-text-attachment sgid="2" presentation="gallery"><figure class="attachment"><img src="photo2.jpg"></figure></action-text-attachment></div>'
    result = Html::StripGalleryAttachmentChildren.new.transform(input)

    assert_includes result, '<div class="attachment-gallery attachment-gallery--2">'
    assert_includes result, 'sgid="1"'
    assert_includes result, 'sgid="2"'
    assert_not_includes result, "<figure"
    assert_not_includes result, "<img"
  end

  test "leaves standalone attachments untouched" do
    input = '<action-text-attachment sgid="1"><figure class="attachment"><img src="photo.jpg"></figure></action-text-attachment>'
    result = Html::StripGalleryAttachmentChildren.new.transform(input)

    assert_includes result, "<figure"
  end

  test "returns html unchanged when no gallery present" do
    input = "<p>Hello world</p>"
    assert_equal input, Html::StripGalleryAttachmentChildren.new.transform(input)
  end
end
