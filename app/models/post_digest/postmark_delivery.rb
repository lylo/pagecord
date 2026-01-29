class PostDigest::PostmarkDelivery
  BATCH_SIZE = 50

  def initialize(digest)
    @digest = digest
    @client = Postmark::ApiClient.new(api_token)
  end

  def deliver_all
    pending_subscribers.find_in_batches(batch_size: BATCH_SIZE) do |subscribers|
      deliver_batch(subscribers)
    end
  end

  private

    def pending_subscribers
      @digest.blog.email_subscribers.confirmed
        .where.not(id: @digest.deliveries.select(:email_subscriber_id))
    end

    def deliver_batch(subscribers)
      messages_with_subscribers = subscribers.map { |s| [ build_email(s), s ] }
      send_and_record(messages_with_subscribers)
    end

    def build_email(subscriber)
      message = PostDigestMailer.with(digest: @digest, subscriber: subscriber).weekly_digest
      Premailer::Rails::Hook.delivering_email(message)
      message
    end

    def send_and_record(messages_with_subscribers)
      messages = messages_with_subscribers.map(&:first)
      subscribers = messages_with_subscribers.map(&:last)

      @client.deliver_messages(messages).zip(subscribers).each do |result, subscriber|
        if result[:error_code] == 0
          @digest.deliveries.create!(email_subscriber: subscriber, delivered_at: Time.current)
        else
          Rails.logger.error "Digest delivery failed for subscriber #{subscriber.id}: #{result[:message]}"
        end
      end
    end

    def api_token
      Rails.application.config.action_mailer.postmark_settings&.dig(:api_token) || ENV["POSTMARK_API_TOKEN"]
    end
end
