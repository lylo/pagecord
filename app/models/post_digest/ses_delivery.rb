class PostDigest::SesDelivery
  BATCH_SIZE = 50
  MAX_SENDS_PER_SECOND = ENV.fetch("SES_MAX_SENDS_PER_SECOND", 14).to_i
  PRIMARY_REGION = ENV.fetch("AWS_SES_REGION", "eu-west-2")
  FAILOVER_REGION = "eu-west-1"

  class ServiceError < StandardError; end

  def initialize(digest, region: PRIMARY_REGION)
    @digest = digest
    @client = build_client(region)
    @sends_this_second = 0
    @second_started_at = nil
  end

  def deliver_all
    pending_subscribers.find_in_batches(batch_size: BATCH_SIZE) do |subscribers|
      deliver_batch(subscribers)
    end
    @digest.update!(delivered_at: Time.current)
  end

  def self.deliver_with_failover(digest)
    new(digest, region: PRIMARY_REGION).deliver_all
  rescue Aws::SESV2::Errors::ServiceError, Seahorse::Client::NetworkingError => e
    Rails.logger.warn "SES primary region failed (#{e.class}: #{e.message}), retrying with #{FAILOVER_REGION}"
    new(digest, region: FAILOVER_REGION).deliver_all
  end

  private

    def pending_subscribers
      suppressed_emails = Email::Suppression.pluck(:email)

      scope = @digest.blog.email_subscribers.confirmed
        .where.not(id: @digest.deliveries.select(:email_subscriber_id))

      scope = scope.where.not(email: suppressed_emails) if suppressed_emails.any?
      scope
    end

    def deliver_batch(subscribers)
      subscribers.each do |subscriber|
        throttle!
        message = build_email(subscriber)
        send_and_record(message, subscriber)
      end
    end

    def build_email(subscriber)
      action = @digest.individual? ? :individual : :weekly_digest
      message = PostDigestMailer.with(digest: @digest, subscriber: subscriber).public_send(action)
      message.from = "#{@digest.blog.display_name} <digest@send.pagecord.com>"
      Premailer::Rails::Hook.delivering_email(message)
      message
    end

    def send_and_record(message, subscriber)
      response = @client.send_email(
        content: { raw: { data: message.to_s } },
        from_email_address: message.from.first
      )

      delivery = @digest.deliveries.create!(email_subscriber: subscriber, delivered_at: Time.current)
      Email::Event.create!(
        message_id: response.message_id,
        provider: "ses",
        post_digest_delivery: delivery
      )
    rescue Aws::SESV2::Errors::MessageRejected => e
      Rails.logger.error "SES rejected message for subscriber #{subscriber.id}: #{e.message}"
    end

    def throttle!
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      if @second_started_at.nil? || (now - @second_started_at) >= 1.0
        @second_started_at = now
        @sends_this_second = 0
      end

      @sends_this_second += 1

      if @sends_this_second > MAX_SENDS_PER_SECOND
        sleep_time = 1.0 - (now - @second_started_at)
        sleep(sleep_time) if sleep_time > 0
        @second_started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @sends_this_second = 1
      end
    end

    def build_client(region)
      Aws::SESV2::Client.new(
        region: region,
        credentials: Aws::Credentials.new(
          ENV["AWS_SES_ACCESS_KEY_ID"],
          ENV["AWS_SES_SECRET_ACCESS_KEY"]
        )
      )
    end
end
