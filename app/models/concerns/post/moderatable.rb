module Post::Moderatable
  extend ActiveSupport::Concern

  included do
    has_one :content_moderation, dependent: :destroy

    scope :with_content_moderation, -> { includes(:content_moderation) }
    scope :moderation_flagged, -> { joins(:content_moderation).where(content_moderations: { status: :flagged }) }
    scope :moderation_pending, -> { left_joins(:content_moderation).where(content_moderations: { id: nil }).or(left_joins(:content_moderation).where(content_moderations: { status: [ :pending, :error ] })) }

    after_commit :queue_moderation_on_publish, on: [ :create, :update ]
  end

  def moderation_text_payload
    [ title, plain_text_content ].compact.join("\n\n").strip.presence
  end

  def moderation_image_payloads
    moderation_images.filter_map do |attachment|
      blob = attachment.respond_to?(:blob) ? attachment.blob : attachment
      next unless blob.image?

      base64_data = Base64.strict_encode64(blob.download)
      content_type = blob.content_type || "image/jpeg"

      {
        type: "image_url",
        image_url: { url: "data:#{content_type};base64,#{base64_data}" }
      }
    end
  end

  def needs_moderation?
    return true if content_moderation.nil?
    return true if content_moderation.pending? || content_moderation.error?
    return true if content_moderation.fingerprint.blank?
    content_moderation.fingerprint != compute_moderation_fingerprint
  end

  def moderation_fingerprint
    compute_moderation_fingerprint
  end

  def queue_moderation_check(delay: 10.minutes)
    ContentModerationJob.set(wait: delay).perform_later(id)
  end

  private

    def queue_moderation_on_publish
      return unless published? && !hidden? && !discarded?
      return unless needs_moderation?
      queue_moderation_check
    end

    def compute_moderation_fingerprint
      content_parts = [
        title.to_s,
        plain_text_content.to_s,
        moderation_image_fingerprints.join(",")
      ]
      Digest::SHA256.hexdigest(content_parts.join("|"))
    end

    def moderation_image_fingerprints
      moderation_images.map do |attachment|
        blob = attachment.respond_to?(:blob) ? attachment.blob : attachment
        blob.checksum
      end.sort
    end

    # Limit to 5 images to stay within OpenAI payload limits and manage memory.
    def moderation_images
      images = []
      images += content_image_attachments if content.body.present?
      images += attachments.select(&:image?)
      images.uniq { |a| a.respond_to?(:blob) ? a.blob.id : a.id }.first(5)
    end
end
