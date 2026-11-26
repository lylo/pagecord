class DeliverabilityReport
  CACHE_KEY = "deliverability/count"
  CACHE_TTL = 8.days
  REASONS = { "BOUNCE" => "Hard bounce", "COMPLAINT" => "Spam complaint" }.freeze
  MetricsError = Class.new(StandardError)
  SES_ERRORS = [ Aws::Errors::ServiceError, Aws::Errors::MissingCredentialsError, Seahorse::Client::NetworkingError, MetricsError ].freeze
  HEALTH_PERIOD = 30.days
  HEALTH_METRICS = { sent: "SEND", bounces: "PERMANENT_BOUNCE", complaints: "COMPLAINT" }.freeze
  # AWS reviews an account whose rates reach these.
  BOUNCE_RATE_LIMIT = 0.05
  COMPLAINT_RATE_LIMIT = 0.001
  BOUNCE_RATE_MINIMUM_SENT = 100
  COMPLAINT_RATE_MINIMUM_SENT = 1_000
  COMPLAINT_RATE_MINIMUM_COMPLAINTS = 5

  # Rows come from the SES suppression list, not the database, so an issue is keyed by email address.
  Issue = Struct.new(:email, :reason, :last_seen_at, :subscribers, keyword_init: true)

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
      elsif complaint_rate_judgeable? && complaint_rate >= COMPLAINT_RATE_LIMIT
        "SES complaint rate is at AWS's review level"
      elsif sent >= BOUNCE_RATE_MINIMUM_SENT && bounce_rate >= BOUNCE_RATE_LIMIT
        "SES bounce rate is at AWS's review level"
      end
    end

    def complaint_rate_judgeable?
      sent >= COMPLAINT_RATE_MINIMUM_SENT || complaints >= COMPLAINT_RATE_MINIMUM_COMPLAINTS
    end
  end

  def self.cached_count
    Rails.cache.read(CACHE_KEY)
  end

  def initialize(client: SesEmail::DeliveryMethod.client)
    @client = client
  end

  def issues
    @issues ||= with_subscribers(suppressed)
  end

  def health
    @health ||= begin
      account = @client.get_account
      Health.new(status: account.enforcement_status, sending_enabled: account.sending_enabled, **sending_totals)
    end
  end

  def cache_count!
    Rails.cache.write(CACHE_KEY, issues.size, expires_in: CACHE_TTL)
  end

  private

    def suppressed
      @client.list_suppressed_destinations.flat_map(&:suppressed_destination_summaries).map do |suppression|
        Issue.new(
          email: suppression.email_address,
          reason: REASONS.fetch(suppression.reason, suppression.reason),
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
      response = @client.batch_get_metric_data(queries: queries)
      raise MetricsError, response.errors.map(&:message).to_sentence if response.errors.any?
      results = response.results.index_by(&:id)

      HEALTH_METRICS.keys.index_with { |name| results[name.to_s]&.values.to_a.sum.to_i }
    end

    def with_subscribers(issues)
      subscribers = EmailSubscriber.includes(:blog)
        .where("lower(email) IN (?)", issues.map { |issue| issue.email.downcase })
        .group_by { |subscriber| subscriber.email.downcase }

      issues.filter_map { |issue|
        issue.subscribers = subscribers[issue.email.downcase]
        issue if issue.subscribers.present?
      }.sort_by { |issue| issue.last_seen_at || Time.at(0) }.reverse
    end
end
