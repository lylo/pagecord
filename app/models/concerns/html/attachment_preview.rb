module Html::AttachmentPreview
  extend ActiveSupport::Concern

  def attachment_preview_node(blob, url, original)
    ActionText::Attachment.from_attachable(blob, url: url).to_html
  end
end
