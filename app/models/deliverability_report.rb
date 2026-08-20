class DeliverabilityReport
  STREAM = "broadcast"
  BOUNCE_THRESHOLD = 3
  # Types that condemn an address on their own. Everything else, notably Transient,
  # only matters when it keeps happening.
  FATAL_TYPES = %w[ HardBounce SpamComplaint BadEmailAddress Blocked ].freeze
  BATCH_SIZE = 500
  CACHE_KEY = "deliverability/actionable_count"
  CACHE_TTL = 8.days

  # Rows come from Postmark, not the database, so an issue is keyed by email address.
  Issue = Struct.new(:email, :reason, :bounce_type, :message_ids, :last_seen_at, :subscribers,
                     keyword_init: true) do
    # Postmark records a bounce per delivery attempt, so count the messages that failed
    # rather than the attempts it took to give up on them.
    def bounce_count
      message_ids&.size || 0
    end

    # What to badge the row with: a suppression reason, or the most recent bounce type.
    def type
      reason || bounce_type
    end

    def label
      return reason if reason
      bounce_count > 1 ? "#{bounce_type} ×#{bounce_count}" : bounce_type
    end

    def actionable?
      reason.present? || FATAL_TYPES.include?(bounce_type) || bounce_count >= BOUNCE_THRESHOLD
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
          last_seen_at: suppression[:created_at]&.to_time
        )
      end
    end

    # Every bounce type, not just soft bounces: most of what Postmark shows as
    # undeliverable arrives as Transient. A suppressed address always wins, so it is
    # only ever counted once.
    def bounced
      @client.bounces(messagestream: STREAM, count: BATCH_SIZE)
        .each_with_object({}) { |bounce, issues| record_bounce(issues, bounce) }
        .except(*suppressed.map { |issue| issue.email.downcase })
        .values
    end

    def record_bounce(issues, bounce)
      issue = issues[bounce[:email].downcase] ||= Issue.new(email: bounce[:email], message_ids: Set.new)
      issue.message_ids << (bounce[:message_id] || bounce[:id])

      bounced_at = bounce[:bounced_at]&.to_time
      if issue.last_seen_at.nil? || (bounced_at && bounced_at > issue.last_seen_at)
        issue.last_seen_at = bounced_at
        issue.bounce_type = bounce[:type]
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
