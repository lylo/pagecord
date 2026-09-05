# Writes the [billing] lines `rake logs:billing` reads. Call from a controller,
# never a job: LogParser skips log lines without a request context header.
class BillingEventLog
  TAG = "[billing]".freeze

  class << self
    def record(event, for_subscription: nil, for_user: nil, **fields)
      attributes = { event: event }
        .merge(identity(for_subscription, for_user))
        .merge(fields)

      Rails.logger.info(line_for(attributes))
    rescue => error
      Sentry.capture_exception(error) if Sentry.initialized?
    end

    private

      def identity(subscription, user)
        subscription ||= user&.subscription
        user ||= subscription&.user

        {
          user: user&.id,
          blog: user&.blog&.subdomain,
          plan: subscription&.plan,
          amount: subscription&.unit_price
        }
      end

      def line_for(attributes)
        pairs = attributes.filter_map do |key, value|
          next if value.nil? || value == ""
          "#{key}=#{value_for(value)}"
        end

        "#{TAG} #{pairs.join(" ")}"
      end

      # Space separates one key=value from the next, so no value may contain one.
      def value_for(value)
        value.respond_to?(:strftime) ? value.strftime("%F") : value.to_s.tr(" ", "_")
      end
  end
end
