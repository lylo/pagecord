module Html::AttachmentPreview
  extend ActiveSupport::Concern

  def attachment_preview_node(blob, url, attributes: {})
    ActionText::Attachment.from_attachable(
      blob,
      attributes.merge(url: url)
    ).to_html
  end
end
