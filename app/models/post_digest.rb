class PostDigest < ApplicationRecord
  belongs_to :blog

  has_many :digest_posts, dependent: :destroy
  has_many :posts, through: :digest_posts
  has_many :deliveries, class_name: "PostDigestDelivery", dependent: :destroy
  has_many :recipients, class_name: "EmailSubscriber", through: :deliveries, source: :email_subscriber

  scope :delivered, -> { where.not(delivered_at: nil) }
  scope :undelivered, -> { where(delivered_at: nil) }

  def self.generate_for(blog)
    return nil unless blog.user.subscribed? && blog.email_subscriptions_enabled?

    Rails.logger.info "Generating digest for #{blog.subdomain}"
    last_digest = blog.post_digests.delivered.order(created_at: :desc).first
    since_date = last_digest&.created_at || 1.week.ago

    new_posts = blog.posts.visible
      .where.not(id: DigestPost.select(:post_id))
      .where("published_at > ?", since_date)

    Rails.logger.info "Found #{new_posts.count} published posts since last digest"

    return nil if new_posts.empty?

    transaction do
      digest = create!(blog: blog)
      new_posts.each { |post| digest.digest_posts.create!(post: post) }
      digest
    end
  end

  def deliver
    return if delivered_at?

    SendPostDigestBatchJob.perform_later(id)
    update!(delivered_at: Time.current)
  end

  def subject
    I18n.with_locale(blog.locale) do
      I18n.t(
        "email_subscribers.mailers.weekly_digest.subject",
        blog_name: blog.display_name,
        date: I18n.l(created_at.to_date, format: :post_date)
      )
    end
  end

  def masked_id
    # Simple obfuscation: XOR with a constant and encode in base36
    obfuscated = id ^ 0x5a5a5a5a
    obfuscated.to_s(36)
  end

  def self.find_by_masked_id(masked_id)
    return nil if masked_id.blank?

    # Decode and XOR back to get original ID
    obfuscated = masked_id.to_i(36)
    real_id = obfuscated ^ 0x5a5a5a5a
    find_by(id: real_id)
  rescue => e
    Rails.logger.warn "Invalid masked digest ID: #{masked_id}"
    nil
  end
end
