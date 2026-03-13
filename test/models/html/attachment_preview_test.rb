require "test_helper"

class Html::AttachmentPreviewTest < ActiveSupport::TestCase
  include Html::AttachmentPreview

  test "builds blob attachment html with canonical attributes" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("abc"),
      filename: "x.png",
      content_type: "image/png",
      metadata: { width: 10, height: 20 }
    )

    html = attachment_preview_node(
      blob,
      Rails.application.routes.url_helpers.rails_blob_url(blob, only_path: true),
      attributes: { caption: "Example image", presentation: "gallery" }
    )

    assert_includes html, "action-text-attachment"
    assert_includes html, 'sgid="'
    assert_includes html, 'url="/rails/active_storage/blobs/redirect/'
    assert_includes html, 'content-type="image/png"'
    assert_includes html, 'filename="x.png"'
    assert_includes html, 'width="10"'
    assert_includes html, 'height="20"'
    assert_includes html, 'caption="Example image"'
    assert_includes html, 'presentation="gallery"'
  end
end
