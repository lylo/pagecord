class PurgeUnattachedBlobsJob < ApplicationJob
  queue_as :default

  def perform
    blobs = ActiveStorage::Blob.unattached.where("active_storage_blobs.created_at < ?", 24.hours.ago)
    count = 0
    blobs.find_each { |blob| blob.purge_later; count += 1 }
    Rails.logger.info "Purged #{count} unattached #{"blob".pluralize(count)}"
  end
end
