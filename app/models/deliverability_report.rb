class DeliverabilityReport
  STREAM = "broadcast"
  BOUNCE_THRESHOLD = 3
  # Types that condemn an address on their own. Everything else, notably Transient,
  # only matters when it keeps happening.
  FATAL_TYPES = %w[ HardBounce SpamComplaint BadEmailAddress Blocked ].freeze
  BATCH_SIZE = 500
  CACHE_KEY = "deliverability/actionable_count"
  CACHE_TTL = 8.days
  SES_REASONS = { "BOUNCE" => "HardBounce", "COMPLAINT" => "SpamComplaint" }.freeze
  MetricsError = Class.new(StandardError)
  SES_ERRORS = [ Aws::Errors::ServiceError, Aws::Errors::MissingCredentialsError, Seahorse::Client::NetworkingError, MetricsError ].freeze
  HEALTH_PERIOD = 30.days
  HEALTH_METRICS = { sent: "SEND", bounces: "PERMANENT_BOUNCE", complaints: "COMPLAINT" }.freeze
  # AWS reviews an account whose rates reach these.
  BOUNCE_RATE_LIMIT = 0.05
  COMPLAINT_RATE_LIMIT = 0.001
  HEALTH_MINIMUM_SENT = 1_000

  # Rows come from SES and Postmark, not the database, so an issue is keyed by email address.
  Issue = Struct.new(:email, :source, :reason, :bounce_type, :message_ids, :last_seen_at, :subscribers,
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

  Health = Struct.new(:status, :sending_enabled, :sent, :bounces, :complaints, keyword_init: true) do
    def bounce_rate
      sent.zero? ? 0.0 : bounces.fdiv(sent)
    end

    def complaint_rate
      sent.zero? ? 0.0 : complaints.fdiv(sent)
    end

    def warning
      if !sending_enabled
        "SES has paused sending"
      elsif status != "HEALTHY"
        "SES account status is #{status}"
      elsif sent < HEALTH_MINIMUM_SENT
        nil
      elsif bounce_rate >= BOUNCE_RATE_LIMIT
        "SES bounce rate is at AWS's review level"
      elsif complaint_rate >= COMPLAINT_RATE_LIMIT
        "SES complaint rate is at AWS's review level"
      end
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

  def initialize(client: self.class.client, ses_client: SesEmail::DeliveryMethod.client)
    @client = client
    @ses_client = ses_client
  end

  def issues
    @issues ||= with_subscribers((ses_suppressed + suppressed + bounced).uniq { |issue| issue.email.downcase })
  end

  def health
    @health ||= begin
      account = @ses_client.get_account
      Health.new(status: account.enforcement_status, sending_enabled: account.sending_enabled, **sending_totals)
    end
  end

  def actionable
    issues.select(&:actionable?)
  end

  def cache_count!
    Rails.cache.write(CACHE_KEY, actionable.size, expires_in: CACHE_TTL)
  end

  private

    def ses_suppressed
      @ses_client.list_suppressed_destinations.flat_map(&:suppressed_destination_summaries).map do |suppression|
        Issue.new(
          email: suppression.email_address,
          source: "SES",
          reason: SES_REASONS.fetch(suppression.reason, suppression.reason),
          last_seen_at: suppression.last_update_time
        )
      end
    end

    # Virtual Deliverability Manager only accepts whole UTC days.
    def sending_totals
      finish = Time.now.utc.tomorrow.beginning_of_day
      queries = HEALTH_METRICS.map do |name, metric|
        { id: name.to_s, namespace: "VDM", metric: metric, start_date: finish - HEALTH_PERIOD, end_date: finish }
      end
      response = @ses_client.batch_get_metric_data(queries: queries)
      raise MetricsError, response.errors.map(&:message).to_sentence if response.errors.any?
      results = response.results.index_by(&:id)

      HEALTH_METRICS.keys.index_with { |name| results[name.to_s]&.values.to_a.sum.to_i }
    end

    def suppressed
      @client.dump_suppressions(STREAM).map do |suppression|
        Issue.new(
          email: suppression[:email_address],
          source: "Postmark",
          reason: suppression[:suppression_reason],
          last_seen_at: suppression[:created_at]&.to_time
        )
      end
    end

    # Every bounce type, not just soft bounces: most of what Postmark shows as
    # undeliverable arrives as Transient.
    def bounced
      @client.bounces(messagestream: STREAM, count: BATCH_SIZE)
        .each_with_object({}) { |bounce, issues| record_bounce(issues, bounce) }
        .values
    end

    def record_bounce(issues, bounce)
      issue = issues[bounce[:email].downcase] ||= Issue.new(email: bounce[:email], source: "Postmark", message_ids: Set.new)
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
