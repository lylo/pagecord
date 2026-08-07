class Admin::ChurnsController < AdminController
  include Pagy::Method

  MONTHS = 12

  def index
    @recent = Churn.where(occurred_at: 30.days.ago..)
    @by_month = Churn.where(occurred_at: MONTHS.months.ago.beginning_of_month..)
                     .group_by { |churn| churn.occurred_at.to_date.beginning_of_month }
    @paid_subscribers_at_month_end = paid_subscribers_at_month_end
    @pagy, @churns = pagy(Churn.order(occurred_at: :desc), limit: 30)
  end

  private

    # Ordered ascending so the last row written for a month wins, which is the closest
    # thing to a month-end count. Blank for any month before the snapshot job started.
    def paid_subscribers_at_month_end
      Rollup.where(name: "paid_subscribers", interval: "day", time: MONTHS.months.ago.beginning_of_month..)
            .order(:time)
            .each_with_object({}) { |rollup, counts| counts[rollup.time.to_date.beginning_of_month] = rollup.value.to_i }
    end
end
