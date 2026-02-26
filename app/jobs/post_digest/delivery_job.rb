class PostDigest::DeliveryJob < ApplicationJob
  queue_as :newsletters

  retry_on Postmark::UnexpectedHttpResponseError, wait: :polynomially_longer, attempts: 5
  retry_on Postmark::TimeoutError, wait: :polynomially_longer, attempts: 5
  retry_on Aws::SESV2::Errors::ServiceError, wait: :polynomially_longer, attempts: 5
  retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 5

  def perform(post_digest_id)
    digest = PostDigest.find(post_digest_id)

    if !Rails.env.production?
      deliver_via_mailer(digest)
    elsif ses_enabled?(digest.blog)
      PostDigest::SesDelivery.deliver_with_failover(digest)
    else
      PostDigest::PostmarkDelivery.new(digest).deliver_all
    end
  end

  private

    def ses_enabled?(blog)
      Rails.features.for(blog: blog).enabled?(:ses_newsletter_delivery)
    end

    def deliver_via_mailer(digest)
      action = digest.individual? ? :individual : :weekly_digest
      pending = digest.blog.email_subscribers.confirmed
        .where.not(id: digest.deliveries.select(:email_subscriber_id))

      pending.find_each do |subscriber|
        PostDigestMailer.with(digest: digest, subscriber: subscriber).public_send(action).deliver_now
        digest.deliveries.create!(email_subscriber: subscriber, delivered_at: Time.current)
      end
      digest.update!(delivered_at: Time.current)
    end
end
