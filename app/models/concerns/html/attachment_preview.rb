module Html::AttachmentPreview
  extend ActiveSupport::Concern

  def attachment_preview_node(blob, url, original)
    %Q(
      <action-text-attachment sgid="#{blob.attachable_sgid}" content-type="#{original.content_type}"
        filename="#{original.filename}" filesize="#{blob.byte_size}" previewable="true" url="#{url}">
        <figure class="attachment attachment--preview attachment--#{blob.filename.extension}">
          <img alt="" src="#{url}">
        </figure>
      </action-text-attachment>
    )
  end
end
