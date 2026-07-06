module Blog::Moderatable
  extend ActiveSupport::Concern

  included do
    has_one :avatar_moderation, dependent: :destroy
  end

  def moderation_text_payload
    nil
  end

  def moderation_image_payloads
    return [] unless avatar.attached?

    blob = avatar.blob
    return [] unless blob.image?

    base64_data = Base64.strict_encode64(blob.download)
    content_type = blob.content_type || "image/jpeg"

    [ {
      type: "image_url",
      image_url: { url: "data:#{content_type};base64,#{base64_data}" }
    } ]
  end

  def needs_avatar_moderation?
    return false unless avatar.attached?
    return true if avatar_moderation.nil?

    avatar_moderation.fingerprint != avatar_moderation_fingerprint
  end

  def avatar_moderation_fingerprint
    avatar.attached? ? avatar.blob.checksum : nil
  end
end
