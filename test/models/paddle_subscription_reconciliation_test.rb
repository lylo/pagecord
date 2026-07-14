require "test_helper"
require "tmpdir"

class PaddleSubscriptionReconciliationTest < ActiveSupport::TestCase
  class FakePaddleClient
    def initialize(subscriptions_by_status:, scheduled_cancel_subscriptions:, customers:)
      @subscriptions_by_status = subscriptions_by_status
      @scheduled_cancel_subscriptions = scheduled_cancel_subscriptions
      @customers = customers
    end

    def list_subscriptions(status:, scheduled_change_action: nil)
      return @scheduled_cancel_subscriptions if status == "active" && scheduled_change_action == "cancel"

      @subscriptions_by_status.fetch(status, [])
    end

    def customer(customer_id)
      @customers.fetch(customer_id, {})
    end
  end

  test "builds reconciliation counts, discrepancies, and CSVs" do
    joel_subscription = subscriptions(:one)
    annie_subscription = subscriptions(:two)
    pagecord_subscription = subscriptions(:three)
    saul_subscription = subscriptions(:monthly_subscription)

    joel_subscription.update!(paddle_customer_id: "ctm_joel")
    annie_subscription.update!(cancelled_at: 1.day.ago, paddle_customer_id: "ctm_annie")
    pagecord_subscription.update!(plan: :complimentary, paddle_customer_id: "ctm_pagecord")

    active_subscriptions = [
      paddle_subscription(id: joel_subscription.paddle_subscription_id, customer_id: "ctm_joel"),
      paddle_subscription(id: "sub_duplicate_joel", customer_id: "ctm_joel"),
      paddle_subscription(id: annie_subscription.paddle_subscription_id, customer_id: "ctm_annie"),
      paddle_subscription(id: pagecord_subscription.paddle_subscription_id, customer_id: "ctm_pagecord", scheduled_change_action: "cancel"),
      paddle_subscription(id: "sub_custom_data_match", customer_id: "ctm_vivian", custom_data: { "user_id" => users(:vivian).id, "blog_subdomain" => "old-vivian" }),
      paddle_subscription(id: "sub_orphan", customer_id: "ctm_orphan")
    ]
    scheduled_cancel_subscriptions = [
      active_subscriptions.third.merge("scheduled_change" => { "action" => "cancel", "effective_at" => 1.month.from_now.iso8601 }),
      active_subscriptions.fourth
    ]
    client = FakePaddleClient.new(
      subscriptions_by_status: {
        "active" => active_subscriptions,
        "past_due" => [ paddle_subscription(id: "sub_past_due_1"), paddle_subscription(id: "sub_past_due_2") ],
        "trialing" => [ paddle_subscription(id: "sub_trialing") ],
        "paused" => []
      },
      scheduled_cancel_subscriptions:,
      customers: {
        "ctm_vivian" => { "email" => "old-vivian@example.com" },
        "ctm_orphan" => { "email" => "orphan@example.com" }
      }
    )

    Dir.mktmpdir("paddle-reconciliation") do |directory|
      output = StringIO.new
      report = PaddleSubscriptionReconciliation.new(client:, output_directory: directory).run(io: output)

      assert_equal 6, report.active_subscriptions.count
      assert_equal 2, report.scheduled_cancel_subscriptions.count
      assert_equal 2, report.paid_subscriptions.count
      assert_equal 1, report.churning_subscriptions.count
      assert_equal 1, report.comped_subscriptions.count
      assert_equal({ "past_due" => 2, "trialing" => 1, "paused" => 0 }, report.diagnostic_counts)

      assert_discrepancy_count report, "paddle_active_without_user", 1
      assert_discrepancy_count report, "paddle_active_user_not_paid_or_churning", 2
      assert_discrepancy_count report, "pagecord_paid_or_churning_without_active_paddle", 1
      assert_discrepancy_count report, "user_has_multiple_active_paddle_subscriptions", 1
      assert_discrepancy_count report, "paddle_scheduled_cancel_user_not_churning", 1
      assert_discrepancy_count report, "pagecord_churning_without_paddle_scheduled_cancel", 0

      assert_includes output.string, "Paddle active subscription count: 6"
      assert_includes output.string, "Pagecord paid count: 2"
      assert_includes output.string, "Paddle past_due subscription count: 2"

      assert_csv_rows directory, "paddle_active_subscriptions.csv", 6
      assert_csv_rows directory, "paddle_subscription_reconciliation.csv", 7
      assert_csv_rows directory, "paddle_discrepancies.csv", 6

      custom_data_match = CSV.read(File.join(directory, "paddle_active_subscriptions.csv"), headers: true).find { |row| row["paddle_subscription_id"] == "sub_custom_data_match" }
      assert_equal users(:vivian).id.to_s, custom_data_match["matched_user_id"]
      assert_equal "paddle_custom_data_user_id", custom_data_match["match_method"]
      assert_equal "old-vivian", custom_data_match["paddle_custom_data_blog_subdomain"]
    end
  end

  private

    def paddle_subscription(id:, customer_id: "ctm_test", scheduled_change_action: nil, custom_data: nil)
      {
        "id" => id,
        "customer_id" => customer_id,
        "custom_data" => custom_data,
        "status" => "active",
        "scheduled_change" => scheduled_change_action.present? ? { "action" => scheduled_change_action, "effective_at" => 1.month.from_now.iso8601 } : nil,
        "next_billed_at" => 1.month.from_now.iso8601,
        "current_billing_period" => { "ends_at" => 1.month.from_now.iso8601 },
        "items" => [
          {
            "price" => {
              "id" => "pri_test"
            }
          }
        ]
      }
    end

    def assert_discrepancy_count(report, type, count)
      assert_equal count, report.discrepancies.count { |discrepancy| discrepancy.type == type }, "Expected #{count} #{type} discrepancies"
    end

    def assert_csv_rows(directory, filename, count)
      assert_equal count, CSV.read(File.join(directory, filename), headers: true).count
    end
end
