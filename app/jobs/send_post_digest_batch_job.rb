class SendPostDigestBatchJob < ApplicationJob
  retry_on Postmark::UnexpectedHttpResponseError, wait: :polynomially_longer, attempts: 5
  retry_on Postmark::TimeoutError, wait: :polynomially_longer, attempts: 5
  retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 5

  def perform(post_digest_id)
    digest = PostDigest.find(post_digest_id)
    sender = BatchEmailSender.new(provider: :postmark)

    pending_subscribers = digest.blog.email_subscribers.confirmed
      .where.not(id: digest.deliveries.select(:email_subscriber_id))

    pending_subscribers.find_in_batches(batch_size: BatchEmailSender::BATCH_SIZE) do |subscribers|
      messages_with_subscribers = subscribers.map do |subscriber|
        message = PostDigestMailer.with(digest: digest, subscriber: subscriber).weekly_digest
        Premailer::Rails::Hook.delivering_email(message)
        [ message, subscriber ]
      end

      results = sender.send_batch(messages_with_subscribers)

      results.each do |result|
        if result.success
          digest.deliveries.create!(email_subscriber: result.subscriber, delivered_at: Time.current)
        else
          Rails.logger.error "Digest delivery failed for subscriber #{result.subscriber.id}: #{result.error_message}"
        end
      end
    end
  end
end
