class AddPlanToSubscriptions < ActiveRecord::Migration[8.2]
  def change
    remove_column :users, :lifetime, :boolean, default: false, null: false
    add_column :subscriptions, :plan, :string

    reversible do |dir|
      dir.up do
        execute "UPDATE subscriptions SET plan = 'annual'"
        execute "UPDATE subscriptions SET plan = 'complimentary' WHERE complimentary = true"
      end
    end
  end
end
