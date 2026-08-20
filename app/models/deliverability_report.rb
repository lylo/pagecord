class DeliverabilityReport
  STREAM = "broadcast"
  BOUNCE_THRESHOLD = 3
  BATCH_SIZE = 500
  CACHE_KEY = "deliverability/actionable_count"
  CACHE_TTL = 8.days

  # Rows come from Postmark, not the database, so an issue is keyed by email address.
  Issue = Struct.new(:email, :reason, :bounce_count, :last_seen_at, :subscribers, keyword_init: true) do
    def actionable?
      reason.present? || bounce_count >= BOUNCE_THRESHOLD
    end
  end

  def self.client
    Postmark::ApiClient.new(
      Rails.application.config.action_mailer.postmark_settings&.dig(:api_token) ||
      ENV["POSTMARK_API_TOKEN"]
    )
  end

  def self.cached_count
    Rails.cache.read(CACHE_KEY)
  end

  def initialize(client: self.class.client)
    @client = client
  end

  def issues
    @issues ||= with_subscribers(suppressed + bounced)
  end

  def actionable
    issues.select(&:actionable?)
  end

  def cache_count!
    Rails.cache.write(CACHE_KEY, actionable.size, expires_in: CACHE_TTL)
  end

  private

    def suppressed
      @suppressed ||= @client.dump_suppressions(STREAM).map do |suppression|
        Issue.new(
          email: suppression[:email_address],
          reason: suppression[:suppression_reason],
          bounce_count: 0,
          last_seen_at: suppression[:created_at]&.to_time
        )
      end
    end

    # Soft bounces are what Postmark labels "Undeliverable". They never suppress, so a
    # suppressed address always wins and is only counted once.
    def bounced
      @client.bounces(type: "SoftBounce", messagestream: STREAM, count: BATCH_SIZE)
        .each_with_object({}) { |bounce, issues| record_bounce(issues, bounce) }
        .except(*suppressed.map { |issue| issue.email.downcase })
        .values
    end

    def record_bounce(issues, bounce)
      issue = issues[bounce[:email].downcase] ||= Issue.new(email: bounce[:email], bounce_count: 0)
      issue.bounce_count += 1

      bounced_at = bounce[:bounced_at]&.to_time
      if bounced_at && (issue.last_seen_at.nil? || bounced_at > issue.last_seen_at)
        issue.last_seen_at = bounced_at
      end
    end

    def with_subscribers(issues)
      subscribers = EmailSubscriber.includes(:blog)
        .where(email: issues.map { |issue| issue.email.downcase })
        .group_by { |subscriber| subscriber.email.downcase }

      issues.filter_map { |issue|
        issue.subscribers = subscribers[issue.email.downcase]
        issue if issue.subscribers.present?
      }.sort_by { |issue| issue.last_seen_at || Time.at(0) }.reverse
    end
end
