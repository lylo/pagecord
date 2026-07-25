class UploadQuota
  FREE_LIMIT = 50
  # Video is premium only: at 50MB a file it is five times the ceiling of
  # anything else, and free accounts are free to create.
  FREE_CONTENT_TYPES = UploadLimits::CONTENT_TYPES.keys.grep_v(/\Avideo\//).freeze

  def initialize(user)
    @user = user
  end

  # subscribed?, not has_premium_access?: an uncapped trial would hand every
  # signup unmetered hosting for storage we keep forever, repeatable with a
  # fresh account.
  def unlimited?
    @user.subscribed?
  end

  def used
    @used ||= attachments.distinct.count(:blob_id)
  end

  def used_bytes
    ActiveStorage::Blob.where(id: attachments.select(:blob_id)).sum(:byte_size)
  end

  def allowed_content_types
    return UploadLimits::CONTENT_TYPES.keys if unlimited?

    exceeded? ? [] : FREE_CONTENT_TYPES
  end

  def exceeded?
    !unlimited? && used >= FREE_LIMIT
  end

  # The blobs a save would introduce. Anything already counted stays free to
  # re-save, so a lapsed subscriber can still edit a back catalogue of images
  # and video.
  def uncounted(blob_ids)
    blob_ids - attachments.where(blob_id: blob_ids).distinct.pluck(:blob_id)
  end

  private

    # Every attachment belonging to the user's content: embeds in their posts,
    # plus emailed attachments and open graph images. Discarded posts and blogs
    # are included, so delete-and-re-upload doesn't reset usage. Avatars and
    # exports are excluded – they aren't attached to content.
    def attachments
      blog_ids = @user.all_blogs.select(:id)
      post_ids = Post.where(blog_id: blog_ids).select(:id)

      rich_text_ids = ActionText::RichText.where(record_type: "Post", record_id: post_ids).select(:id)

      ActiveStorage::Attachment
        .where(record_type: "ActionText::RichText", record_id: rich_text_ids)
        .or(ActiveStorage::Attachment.where(record_type: "Post", record_id: post_ids))
        .joins(:blob).where(active_storage_blobs: { content_type: UploadLimits::CONTENT_TYPES.keys })
    end
end
