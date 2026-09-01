class CreateAccountTombstones < ActiveRecord::Migration[8.2]
  def change
    create_table :account_tombstones do |t|
      t.datetime :signed_up_at, null: false
      t.datetime :deleted_at, null: false
      t.string :reason, null: false
      t.string :plan
      t.string :subdomain

      t.timestamps
    end

    add_index :account_tombstones, :deleted_at
  end
end
