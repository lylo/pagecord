require_relative "log_parser"

# Reads the [billing] lines BillingEventLog writes.
module LogBilling
  LINE = /\A(?:\[[^\]]*\]\s+)*\[billing\] (?<pairs>.*)/

  MONTHS_PER_TERM = { "monthly" => 12 }.freeze

  # Events that can move the run rate. A renewal never does; the rest are
  # excluded per line when they carry booked_earlier=true, which marks money
  # already counted on the day the customer decided.
  BOOKING_EVENTS = %w[
    subscription_started
    plan_changed
    resumed
    cancel_requested
    cancel_scheduled
    cancel_effective
    account_deleted
  ].freeze

  GAINS = %w[ subscription_started plan_changed resumed ].freeze

  class << self
    def events_for(entries)
      entries.filter_map do |entry|
        next unless entry.line_type == :other

        match = LINE.match(entry.detail.to_s)
        parse(match[:pairs], entry) if match
      end
    end

    def annualised_delta(events)
      events.sum { |event| signed_annual_amount(event) }
    end

    def annualised_amount(event)
      amount = event[:amount].to_i
      return 0 if amount.zero?

      amount * MONTHS_PER_TERM.fetch(event[:plan], 1)
    end

    def books_revenue?(event)
      BOOKING_EVENTS.include?(event[:event]) &&
        event[:booked_earlier] != "true" &&
        event[:paid] != "false" &&
        event[:reason] != "spam"
    end

    private

      def parse(pairs, entry)
        event = { timestamp: entry.timestamp, uuid: entry.uuid }

        pairs.split(" ").each do |pair|
          key, value = pair.split("=", 2)
          next if key.nil? || value.nil?

          event[key.to_sym] = value
        end

        event
      end

      def signed_annual_amount(event)
        return 0 unless books_revenue?(event)

        case event[:event]
        when "plan_changed"
          annualised_amount(event) -
            annualised_amount(event.merge(amount: event[:from_amount], plan: event[:from]))
        when *GAINS
          annualised_amount(event)
        else
          -annualised_amount(event)
        end
      end
  end
end
