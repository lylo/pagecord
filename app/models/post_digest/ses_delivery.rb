class PostDigest::SesDelivery
  BATCH_SIZE = 50
  SENDS_PER_SECOND = Integer(ENV.fetch("AWS_SES_SENDS_PER_SECOND", 14))

  def initialize(digest)
    @digest = digest
    @client = self.class.client
  end

  def self.client
    Aws::SESV2::Client.new(
      region: ENV.fetch("AWS_SES_REGION", "eu-west-2"),
      credentials: Aws::Credentials.new(ENV["AWS_SES_ACCESS_KEY_ID"], ENV["AWS_SES_SECRET_ACCESS_KEY"])
    )
  end

  def deliver_all
    pending_subscribers.find_in_batches(batch_size: BATCH_SIZE) do |subscribers|
      subscribers.each_slice(SENDS_PER_SECOND) do |slice|
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        slice.each { |subscriber| send_and_record(subscriber) }
        pause_until(started + 1)
      end
    end
    @digest.update!(delivered_at: Time.current)
  end

  private

    def pending_subscribers
      @digest.blog.email_subscribers.confirmed
        .where.not(id: @digest.deliveries.select(:email_subscriber_id))
    end

    def build_email(subscriber)
      action = @digest.individual? ? :individual : :weekly_digest
      message = PostDigestMailer.with(digest: @digest, subscriber: subscriber).public_send(action)
      Premailer::Rails::Hook.delivering_email(message)
      message
    end

    def send_and_record(subscriber)
      message = build_email(subscriber)
      @client.send_email(content: { raw: { data: message.to_s } })
      @digest.deliveries.create!(email_subscriber: subscriber, delivered_at: Time.current)
    rescue Aws::SESV2::Errors::MessageRejected => e
      Rails.error.report(e, context: { post_digest_id: @digest.id, email_subscriber_id: subscriber.id })
    end

    def pause_until(deadline)
      remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
      sleep(remaining) if remaining > 0
    end
end
