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

    Rails.logger.info "Generating digest for #{blog.name}"
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

    blog.email_subscribers.confirmed.each do |subscriber|
      PostDigestMailer.with(digest: self, subscriber: subscriber).weekly_digest.deliver_later
      deliveries.create!(email_subscriber: subscriber, delivered_at: Time.current)
    end

    update!(delivered_at: Time.current)
  end
end
