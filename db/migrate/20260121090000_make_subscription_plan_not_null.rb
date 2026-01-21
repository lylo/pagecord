class MakeSubscriptionPlanNotNull < ActiveRecord::Migration[8.2]
  def change
    change_column_null :subscriptions, :plan, false
  end
end
