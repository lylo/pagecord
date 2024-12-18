# config/initializers/active_storage_blob_extension.rb
# Replace the previous implementation with this:
module ActiveStorageBlobExtension
  def to_trix_content_attachment_partial_path
    return "active_storage/blobs/video_attachment" if content_type.start_with?("video/")
    super
  end
end

# Safely extend ActiveStorage::Blob
Rails.configuration.to_prepare do
  ActiveStorage::Blob.class_eval do
    prepend ActiveStorageBlobExtension
  end
end
