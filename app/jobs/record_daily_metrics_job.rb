# A daily snapshot of the numbers that only ever existed as live counts, so we can
# answer "how many paid subscribers did I have in March" after the fact. Rollup rows are
# written directly rather than through the gem's relation API, which aggregates historic
# rows by a time column and is the wrong shape for a point-in-time count.
class RecordDailyMetricsJob < ApplicationJob
  queue_as :default

  def perform(date = Date.current)
    metrics.each do |name, value|
      Rollup.find_or_initialize_by(name: name, interval: "day", time: date, dimensions: {}).update!(value: value)
    end
  end

  private

    def metrics
      {
        "users" => User.kept.count,
        "trialing" => User.kept.where(trial_ends_at: Date.current..).where.missing(:subscription).count,
        "paid_subscribers" => Subscription.active_paid.count,
        "supporters" => Subscription.active_paid.supporter.count,
        "comped_subscribers" => Subscription.comped.count,
        "churning_subscribers" => Subscription.churning.count,
        "mrr_cents" => mrr_cents
      }
    end

    # unit_price is the amount billed per period, in cents. Annual and supporter plans
    # bill yearly, so a twelfth of each counts towards monthly revenue.
    def mrr_cents
      Subscription.active_paid.monthly.sum(:unit_price) +
        Subscription.active_paid.where.not(plan: :monthly).sum(:unit_price) / 12.0
    end
end
