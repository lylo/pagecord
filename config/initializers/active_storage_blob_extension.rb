# config/initializers/active_storage_blob_extension.rb
module ActiveStorageBlobExtension
  def to_editor_content_attachment_partial_path
    return "active_storage/blobs/video_attachment" if content_type.start_with?("video/")
    super
  end
end

# Extend Active Storage only after the blob class is loaded.
ActiveSupport.on_load(:active_storage_blob) do
  prepend ActiveStorageBlobExtension unless ancestors.include?(ActiveStorageBlobExtension)
end
