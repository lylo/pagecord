module PendingPreviewRepresentation
  private

    def set_representation
      if @blob.previewable? && !@blob.preview_image.attached?
        head :accepted
      else
        super
      end
    end
end
