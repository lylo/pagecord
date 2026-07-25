# Deliberately not an EachValidator: those call value.blank? on the attribute,
# which re-renders a RichText body and resolves every embed's sgid.
class UploadQuota::Validator < ActiveModel::Validator
  def validate(record)
    blob_ids = incoming_blob_ids(record.content&.body)
    return if blob_ids.empty?

    quota = record.blog&.user&.upload_quota
    return if quota.nil? || quota.unlimited?

    added = quota.uncounted(blob_ids)
    return if added.empty?

    if ActiveStorage::Blob.where(id: added).where.not(content_type: UploadQuota::FREE_CONTENT_TYPES).exists?
      record.errors.add(:content, "Video uploads need a paid subscription")
    elsif quota.exceeded?
      record.errors.add(:content, "You've used all #{UploadQuota::FREE_LIMIT} free uploads. Subscribe to upload more.")
    end
  end

  private
    # Parses the sgids out of the stored markup rather than asking Action Text
    # for its attachments – ActionText::Content#attachments resolves one blob
    # per node through GlobalID::Locator, ignoring preloads.
    def incoming_blob_ids(body)
      return [] if body.nil?

      body.fragment.find_all("action-text-attachment[sgid]").filter_map { |node|
        gid = SignedGlobalID.parse(node["sgid"], for: ActionText::Attachable::LOCATOR_NAME)
        gid.model_id.to_i if gid&.model_name == "ActiveStorage::Blob"
      }.uniq
    end
end
