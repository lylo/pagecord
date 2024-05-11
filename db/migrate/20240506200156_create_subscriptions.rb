class CreateSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :paddle_subscription_id
      t.string :paddle_customer_id
      t.string :paddle_price_id
      t.integer :unit_price
      t.datetime :next_billed_at
      t.datetime :cancelled_at

      t.timestamps
    end
    add_index :subscriptions, :paddle_customer_id
  end
end
