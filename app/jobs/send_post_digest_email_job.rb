class SendPostDigestEmailJob < ApplicationJob
  queue_as :mailers

  def perform(post_digest_id, email_subscriber_id)
    digest = PostDigest.find(post_digest_id)
    subscriber = EmailSubscriber.find(email_subscriber_id)

    return unless subscriber&.confirmed?
    return if digest.deliveries.exists?(email_subscriber_id: subscriber.id)

    PostDigestMailer.with(digest: digest, subscriber: subscriber).weekly_digest.deliver_now
    digest.deliveries.create!(email_subscriber: subscriber, delivered_at: Time.current)
  end
end
