module StorageTrackable
  extend ActiveSupport::Concern

  # Returns total bytes used by post attachments for this blog
  def attachment_storage_bytes
    attachment_blobs.sum(:byte_size)
  end

  # Returns human-readable storage size (e.g., "144 MB")
  def attachment_storage_size
    ActiveSupport::NumberHelper.number_to_human_size(attachment_storage_bytes)
  end

  # Returns count of attachment files
  def attachment_count
    attachment_blobs.count
  end

  # Returns hash with storage stats
  def storage_stats
    {
      bytes: attachment_storage_bytes,
      size: attachment_storage_size,
      count: attachment_count
    }
  end

  private

    def attachment_blobs
      ActiveStorage::Blob
        .joins("INNER JOIN active_storage_attachments ON active_storage_attachments.blob_id = active_storage_blobs.id")
        .joins("INNER JOIN action_text_rich_texts ON action_text_rich_texts.id = active_storage_attachments.record_id AND active_storage_attachments.record_type = 'ActionText::RichText'")
        .joins("INNER JOIN posts ON posts.id = action_text_rich_texts.record_id AND action_text_rich_texts.record_type = 'Post'")
        .where(posts: { blog_id: id })
    end
end
