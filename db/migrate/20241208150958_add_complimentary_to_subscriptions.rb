class AddComplimentaryToSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :subscriptions, :complimentary, :boolean, default: false, null: false
  end
end
