class AddPlanToSubscriptions < ActiveRecord::Migration[8.2]
  def up
    add_column :subscriptions, :plan, :string

    execute <<-SQL
      UPDATE subscriptions SET plan = CASE WHEN complimentary THEN 'complimentary' ELSE 'annual' END
    SQL

    change_column_null :subscriptions, :plan, false
    remove_column :subscriptions, :complimentary
  end

  def down
    add_column :subscriptions, :complimentary, :boolean, default: false, null: false
    execute "UPDATE subscriptions SET complimentary = true WHERE plan = 'complimentary'"
    remove_column :subscriptions, :plan
  end
end
