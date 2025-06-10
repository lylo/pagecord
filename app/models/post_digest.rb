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

  # Deliver a digest email to each subscriber in a background job,
  # spreading delivery over a random window based on the number of
  # emails to send to avoid mail server overload.
  def deliver
    return if delivered_at?

    total_subs = blog.email_subscribers.confirmed.count
    random_window = [ total_subs * 0.5.seconds, 30.minutes ].min

    blog.email_subscribers.confirmed.find_each(batch_size: 100).with_index do |subscriber, index|
      bump = index * 0.5.seconds
      delay = bump + rand(random_window)

      Rails.logger.info "Scheduling digest delivery for blog #{blog.subdomain} and subscriber #{subscriber.id} with delay #{delay} seconds"

      SendPostDigestEmailJob.set(wait: delay).perform_later(self.id, subscriber.id)
    end

    update!(delivered_at: Time.current)
  end
end
