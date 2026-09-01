class AddUserToAccountTombstones < ActiveRecord::Migration[8.2]
  def change
    add_column :account_tombstones, :user_id, :bigint
    add_index :account_tombstones, :user_id
  end
end
