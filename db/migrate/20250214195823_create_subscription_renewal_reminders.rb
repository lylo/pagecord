class CreateSubscriptionRenewalReminders < ActiveRecord::Migration[8.1]
  def change
    create_table :subscription_renewal_reminders do |t|
      t.references :subscription, null: false, foreign_key: true
      t.string :period, null: false
      t.datetime :sent_at, null: false
      t.timestamps
    end

    add_index :subscription_renewal_reminders, [ :subscription_id, :period ],
      unique: true
  end
end
