module DirectUploadPreviewStatus
  private

    def direct_upload_json(blob)
      super.tap { |json| json[:preview_status_url] = main_app.app_preview_path(blob.signed_id) if blob.previewable? }
    end
end
