require "csv"
require "fileutils"
require "httparty"
require "set"

class PaddleSubscriptionReconciliation
  DIAGNOSTIC_STATUSES = %w[past_due trialing paused].freeze

  ACTIVE_SUBSCRIPTION_HEADERS = [
    "paddle_subscription_id",
    "paddle_customer_id",
    "paddle_status",
    "scheduled_change_action",
    "scheduled_change_effective_at",
    "next_billed_at",
    "current_billing_period_ends_at",
    "price_id",
    "matched_user_id",
    "matched_user_email",
    "matched_subscription_id",
    "match_method",
    "local_plan",
    "local_state",
    "local_cancelled_at",
    "local_next_billed_at"
  ].freeze

  RECONCILIATION_HEADERS = [
    "record_type",
    "paddle_subscription_id",
    "paddle_customer_id",
    "paddle_status",
    "paddle_scheduled_change_action",
    "paddle_customer_email",
    "user_id",
    "user_email",
    "local_subscription_id",
    "local_paddle_subscription_id",
    "local_paddle_customer_id",
    "local_plan",
    "local_state",
    "match_method",
    "notes"
  ].freeze

  DISCREPANCY_HEADERS = [
    "type",
    "paddle_subscription_id",
    "paddle_customer_id",
    "paddle_customer_email",
    "user_id",
    "user_email",
    "local_subscription_id",
    "local_plan",
    "local_state",
    "details"
  ].freeze

  Match = Struct.new(:user, :subscription, :method, keyword_init: true)
  Discrepancy = Struct.new(:type, :subscription, :match, :details, keyword_init: true)
  Report = Struct.new(
    :active_subscriptions,
    :scheduled_cancel_subscriptions,
    :active_subscriptions_by_customer_id,
    :diagnostic_counts,
    :matches_by_subscription_id,
    :paid_subscriptions,
    :churning_subscriptions,
    :comped_subscriptions,
    :discrepancies,
    :csv_paths,
    keyword_init: true
  )

  def initialize(client: PaddleClient.new, output_directory: Rails.root.join("tmp"))
    @client = client
    @output_directory = Pathname(output_directory)
  end

  def run(io: $stdout)
    report = build_report
    write_csvs(report)
    print_report(report, io)
    report
  end

  def build_report
    active_subscriptions = client.list_subscriptions(status: "active")
    scheduled_cancel_subscriptions = client.list_subscriptions(status: "active", scheduled_change_action: "cancel")
    scheduled_cancel_ids = subscription_ids_for(scheduled_cancel_subscriptions)
    matches_by_subscription_id = active_subscriptions.each_with_object({}) do |subscription, matches|
      matches[subscription_id(subscription)] = match_for(subscription)
    end
    active_subscriptions_by_user_id = active_subscriptions.group_by { |subscription| matches_by_subscription_id[subscription_id(subscription)]&.user&.id }
                                                       .except(nil)

    Report.new(
      active_subscriptions:,
      scheduled_cancel_subscriptions:,
      active_subscriptions_by_customer_id: active_subscriptions.group_by { |subscription| customer_id(subscription) },
      diagnostic_counts: diagnostic_counts,
      matches_by_subscription_id:,
      paid_subscriptions: paid_subscriptions,
      churning_subscriptions: churning_subscriptions,
      comped_subscriptions: comped_subscriptions,
      discrepancies: discrepancies_for(active_subscriptions, matches_by_subscription_id, scheduled_cancel_ids, active_subscriptions_by_user_id),
      csv_paths: csv_paths
    )
  end

  private

    attr_reader :client, :output_directory

    def diagnostic_counts
      DIAGNOSTIC_STATUSES.index_with { |status| client.list_subscriptions(status: status).count }
    end

    def discrepancies_for(active_subscriptions, matches_by_subscription_id, scheduled_cancel_ids, active_subscriptions_by_user_id)
      discrepancies = []

      active_subscriptions.each do |paddle_subscription|
        match = matches_by_subscription_id[subscription_id(paddle_subscription)]

        if match.blank?
          discrepancies << discrepancy("paddle_active_without_user", paddle_subscription, nil, "Paddle active subscription has no matching local user")
        elsif !local_paid?(match.subscription) && !local_churning?(match.subscription)
          discrepancies << discrepancy("paddle_active_user_not_paid_or_churning", paddle_subscription, match, "Matched user is not marked paid or churning locally")
        end

        if scheduled_cancel_ids.include?(subscription_id(paddle_subscription)) && !local_churning?(match&.subscription)
          discrepancies << discrepancy("paddle_scheduled_cancel_user_not_churning", paddle_subscription, match, "Paddle subscription is scheduled to cancel but local user is not marked churning")
        end
      end

      (paid_subscriptions + churning_subscriptions).uniq.each do |local_subscription|
        active_for_user = active_subscriptions_by_user_id[local_subscription.user_id] || []

        if active_for_user.blank?
          discrepancies << discrepancy("pagecord_paid_or_churning_without_active_paddle", nil, match_for_local(local_subscription), "Local paid or churning user has no active Paddle subscription")
        end
      end

      active_subscriptions_by_user_id.each_value do |subscriptions|
        next unless subscriptions.count > 1

        match = matches_by_subscription_id[subscription_id(subscriptions.first)]
        discrepancies << discrepancy("user_has_multiple_active_paddle_subscriptions", subscriptions.first, match, "Matched user has #{subscriptions.count} active Paddle subscriptions: #{subscriptions.map { |subscription| subscription_id(subscription) }.join(", ")}")
      end

      churning_subscriptions.each do |local_subscription|
        active_for_user = active_subscriptions_by_user_id[local_subscription.user_id] || []
        scheduled_for_user = active_for_user.any? { |subscription| scheduled_cancel_ids.include?(subscription_id(subscription)) }
        next if scheduled_for_user

        details = active_for_user.present? ? "Local user is churning but matched active Paddle subscription is not scheduled to cancel" : "Local user is churning but no active Paddle subscription was matched"
        discrepancies << discrepancy("pagecord_churning_without_paddle_scheduled_cancel", active_for_user.first, match_for_local(local_subscription), details)
      end

      discrepancies
    end

    def write_csvs(report)
      FileUtils.mkdir_p(output_directory)

      CSV.open(csv_paths[:active_subscriptions], "w", write_headers: true, headers: ACTIVE_SUBSCRIPTION_HEADERS) do |csv|
        report.active_subscriptions.each do |paddle_subscription|
          match = report.matches_by_subscription_id[subscription_id(paddle_subscription)]
          csv << active_subscription_row(paddle_subscription, match)
        end
      end

      CSV.open(csv_paths[:reconciliation], "w", write_headers: true, headers: RECONCILIATION_HEADERS) do |csv|
        report.active_subscriptions.each do |paddle_subscription|
          match = report.matches_by_subscription_id[subscription_id(paddle_subscription)]
          csv << reconciliation_row("paddle_active", paddle_subscription, match, nil)
        end

        (report.paid_subscriptions + report.churning_subscriptions + report.comped_subscriptions).uniq.each do |local_subscription|
          next if report.active_subscriptions.any? { |paddle_subscription| report.matches_by_subscription_id[subscription_id(paddle_subscription)]&.subscription == local_subscription }

          csv << reconciliation_row("pagecord_subscription", nil, match_for_local(local_subscription), "No matched active Paddle subscription")
        end
      end

      CSV.open(csv_paths[:discrepancies], "w", write_headers: true, headers: DISCREPANCY_HEADERS) do |csv|
        report.discrepancies.each do |discrepancy|
          csv << discrepancy_row(discrepancy)
        end
      end
    end

    def print_report(report, io)
      scheduled_cancel_ids = subscription_ids_for(report.scheduled_cancel_subscriptions)

      io.puts "Paddle subscription reconciliation"
      io.puts
      io.puts "Paddle active subscription count: #{report.active_subscriptions.count}"
      io.puts "Paddle active scheduled-cancel count: #{scheduled_cancel_ids.count}"
      io.puts "Paddle active not scheduled-cancel count: #{report.active_subscriptions.count - scheduled_cancel_ids.count}"
      io.puts "Pagecord paid count: #{report.paid_subscriptions.count}"
      io.puts "Pagecord churning count: #{report.churning_subscriptions.count}"
      io.puts "Pagecord comped count: #{report.comped_subscriptions.count}"
      io.puts
      io.puts "Diagnostics:"
      report.diagnostic_counts.each do |status, count|
        io.puts "Paddle #{status} subscription count: #{count}"
      end
      io.puts

      print_discrepancy_list(io, report, "Paddle active subscriptions with no matching user", "paddle_active_without_user")
      print_discrepancy_list(io, report, "Paddle active subscriptions matched to users not marked paid or churning", "paddle_active_user_not_paid_or_churning")
      print_discrepancy_list(io, report, "Pagecord paid/churning users with no active Paddle subscription", "pagecord_paid_or_churning_without_active_paddle")
      print_discrepancy_list(io, report, "Users with more than one active Paddle subscription", "user_has_multiple_active_paddle_subscriptions")
      print_discrepancy_list(io, report, "Paddle active subscriptions scheduled to cancel where user is not marked churning", "paddle_scheduled_cancel_user_not_churning")
      print_discrepancy_list(io, report, "Users marked churning where Paddle subscription has no scheduled_change.action=cancel", "pagecord_churning_without_paddle_scheduled_cancel")

      io.puts "CSV files written:"
      csv_paths.each_value { |path| io.puts "- #{path}" }
    end

    def print_discrepancy_list(io, report, title, type)
      discrepancies = report.discrepancies.select { |discrepancy| discrepancy.type == type }

      io.puts "#{title}: #{discrepancies.count}"
      if discrepancies.any?
        discrepancies.each do |discrepancy|
          io.puts "- #{summary_for(discrepancy)}"
        end
      end
      io.puts
    end

    def summary_for(discrepancy)
      paddle_subscription = discrepancy.subscription
      match = discrepancy.match
      [
        ("paddle_subscription_id=#{subscription_id(paddle_subscription)}" if paddle_subscription),
        ("paddle_customer_id=#{customer_id(paddle_subscription)}" if paddle_subscription),
        ("customer_email=#{customer_email(paddle_subscription)}" if paddle_subscription && customer_email(paddle_subscription).present?),
        ("user_id=#{match.user.id}" if match&.user),
        ("user_email=#{match.user.email}" if match&.user),
        ("local_subscription_id=#{match.subscription.id}" if match&.subscription),
        discrepancy.details
      ].compact.join(", ")
    end

    def active_subscription_row(paddle_subscription, match)
      local_subscription = match&.subscription
      [
        subscription_id(paddle_subscription),
        customer_id(paddle_subscription),
        paddle_subscription["status"],
        scheduled_change_action(paddle_subscription),
        scheduled_change_effective_at(paddle_subscription),
        paddle_subscription["next_billed_at"],
        paddle_subscription.dig("current_billing_period", "ends_at"),
        paddle_subscription.dig("items", 0, "price", "id"),
        match&.user&.id,
        match&.user&.email,
        local_subscription&.id,
        match&.method,
        local_subscription&.plan,
        local_state(local_subscription),
        local_subscription&.cancelled_at&.iso8601,
        local_subscription&.next_billed_at&.iso8601
      ]
    end

    def reconciliation_row(record_type, paddle_subscription, match, notes)
      local_subscription = match&.subscription
      [
        record_type,
        subscription_id(paddle_subscription),
        customer_id(paddle_subscription),
        paddle_subscription&.fetch("status", nil),
        scheduled_change_action(paddle_subscription),
        customer_email(paddle_subscription),
        match&.user&.id,
        match&.user&.email,
        local_subscription&.id,
        local_subscription&.paddle_subscription_id,
        local_subscription&.paddle_customer_id,
        local_subscription&.plan,
        local_state(local_subscription),
        match&.method,
        notes
      ]
    end

    def discrepancy_row(discrepancy)
      paddle_subscription = discrepancy.subscription
      match = discrepancy.match
      local_subscription = match&.subscription

      [
        discrepancy.type,
        subscription_id(paddle_subscription),
        customer_id(paddle_subscription),
        customer_email(paddle_subscription),
        match&.user&.id,
        match&.user&.email,
        local_subscription&.id,
        local_subscription&.plan,
        local_state(local_subscription),
        discrepancy.details
      ]
    end

    def match_for(paddle_subscription)
      if subscription_id(paddle_subscription).present? && subscriptions_by_paddle_subscription_id[subscription_id(paddle_subscription)]
        return match_for_local(subscriptions_by_paddle_subscription_id[subscription_id(paddle_subscription)], "paddle_subscription_id")
      end

      if customer_id(paddle_subscription).present? && subscriptions_by_paddle_customer_id[customer_id(paddle_subscription)]
        return match_for_local(subscriptions_by_paddle_customer_id[customer_id(paddle_subscription)], "paddle_customer_id")
      end

      email = customer_email(paddle_subscription, fetch: true)
      return if email.blank?

      user = users_by_email[email.downcase]
      Match.new(user: user, subscription: user&.subscription, method: "paddle_customer_email") if user
    end

    def match_for_local(subscription, method = "local_subscription")
      Match.new(user: subscription.user, subscription:, method:)
    end

    def subscriptions_by_paddle_subscription_id
      @subscriptions_by_paddle_subscription_id ||= local_subscriptions.select { |subscription| subscription.paddle_subscription_id.present? }
                                                                      .index_by(&:paddle_subscription_id)
    end

    def subscriptions_by_paddle_customer_id
      @subscriptions_by_paddle_customer_id ||= local_subscriptions.select { |subscription| subscription.paddle_customer_id.present? }
                                                                  .index_by(&:paddle_customer_id)
    end

    def users_by_email
      @users_by_email ||= User.includes(:subscription).index_by { |user| user.email.downcase }
    end

    def local_subscriptions
      @local_subscriptions ||= Subscription.includes(:user).to_a
    end

    def paid_subscriptions
      @paid_subscriptions ||= Subscription.active_paid.includes(:user).to_a
    end

    def churning_subscriptions
      @churning_subscriptions ||= Subscription.includes(:user).where.not(cancelled_at: nil).where("next_billed_at > ?", Time.current).to_a
    end

    def comped_subscriptions
      @comped_subscriptions ||= Subscription.comped.includes(:user).to_a
    end

    def local_paid?(subscription)
      subscription&.plan.in?(%w[annual monthly]) &&
        subscription.cancelled_at.blank? &&
        subscription.next_billed_at.present? &&
        subscription.next_billed_at > Time.current
    end

    def local_churning?(subscription)
      subscription&.cancelled_at.present? &&
        subscription.next_billed_at.present? &&
        subscription.next_billed_at > Time.current
    end

    def local_state(subscription)
      return "none" unless subscription
      return "comped" if subscription.complimentary?
      return "churning" if local_churning?(subscription)
      return "paid" if local_paid?(subscription)
      return "lapsed" if subscription.lapsed?
      return "cancelled" if subscription.cancelled?

      "unpaid"
    end

    def discrepancy(type, paddle_subscription, match, details)
      Discrepancy.new(type:, subscription: paddle_subscription, match:, details:)
    end

    def subscription_ids_for(subscriptions)
      subscriptions.map { |subscription| subscription_id(subscription) }.compact.to_set
    end

    def subscription_id(subscription)
      subscription&.fetch("id", nil)
    end

    def customer_id(subscription)
      subscription&.fetch("customer_id", nil)
    end

    def scheduled_change_action(subscription)
      subscription&.dig("scheduled_change", "action")
    end

    def scheduled_change_effective_at(subscription)
      subscription&.dig("scheduled_change", "effective_at")
    end

    def customer_email(subscription, fetch: false)
      return unless subscription

      return subscription.dig("customer", "email") if subscription.dig("customer", "email").present?

      @customer_email_by_customer_id ||= {}
      return @customer_email_by_customer_id[customer_id(subscription)] if @customer_email_by_customer_id.key?(customer_id(subscription))
      return unless fetch && customer_id(subscription).present?

      customer_email_by_customer_id(customer_id(subscription))
    end

    def customer_email_by_customer_id(customer_id)
      @customer_email_by_customer_id ||= {}
      @customer_email_by_customer_id[customer_id] ||= client.customer(customer_id)["email"]
    end

    def csv_paths
      @csv_paths ||= {
        active_subscriptions: output_directory.join("paddle_active_subscriptions.csv"),
        reconciliation: output_directory.join("paddle_subscription_reconciliation.csv"),
        discrepancies: output_directory.join("paddle_discrepancies.csv")
      }
    end

  class PaddleClient
    PADDLE_CONFIG = Rails.application.config_for(:paddle)

    def list_subscriptions(status:, scheduled_change_action: nil)
      params = { status:, per_page: 200 }
      params[:scheduled_change_action] = scheduled_change_action if scheduled_change_action.present?

      list("subscriptions", params)
    end

    def customer(customer_id)
      get("customers/#{customer_id}").fetch("data", {})
    end

    private

      def list(path, params)
        records = []
        url = "#{PADDLE_CONFIG[:base_url]}/#{path}"
        query = params

        loop do
          response = HTTParty.get(url, query:, headers:)
          raise "Paddle API error #{response.code}: #{response.body}" unless response.success?

          parsed = JSON.parse(response.body)
          records.concat(parsed.fetch("data", []))

          next_page = parsed.dig("meta", "pagination", "next")
          has_more = parsed.dig("meta", "pagination", "has_more")
          break unless has_more && next_page.present?

          url = next_page.start_with?("http") ? next_page : "#{PADDLE_CONFIG[:base_url]}#{next_page.start_with?("/") ? "" : "/"}#{next_page}"
          query = nil
        end

        records
      end

      def get(path)
        response = HTTParty.get("#{PADDLE_CONFIG[:base_url]}/#{path}", headers:)
        raise "Paddle API error #{response.code}: #{response.body}" unless response.success?

        JSON.parse(response.body)
      end

      def headers
        {
          "Authorization" => "Bearer #{PADDLE_CONFIG[:api_key]}",
          "Content-Type" => "application/json"
        }
      end
  end
end
