module Post::Emailable
  extend ActiveSupport::Concern

  SEND_WINDOW = 14.days

  included do
    scope :emailed, -> { where(id: delivered_digest_post_ids) }
    scope :not_emailed, -> { where.not(id: delivered_digest_post_ids) }

    def self.delivered_digest_post_ids
      DigestPost.joins(:post_digest).where.not(post_digests: { delivered_at: nil }).select(:post_id)
    end
  end

  def emailed?
    post_digests.any? { |digest| digest.delivered_at.present? }
  end

  def individually_sent?
    post_digests.individual.exists?
  end

  def individually_sendable?
    published_at&.after?(SEND_WINDOW.ago) && individual_send_eligible?
  end

  def send_window_closed?
    published_at&.before?(SEND_WINDOW.ago) && individual_send_eligible?
  end

  def send_to_subscribers!
    digest = PostDigest.generate_individual_for(self)
    digest&.deliver
  end

  private

    def individual_send_eligible?
      persisted? &&
        post? &&
        kept? &&
        published? &&
        !pending? &&
        post_digests.none? &&
        blog.individual? &&
        blog.accepts_subscribers? &&
        blog.email_subscribers.confirmed.exists?
    end
end
