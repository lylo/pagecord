class AddStatusToPost < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :status, :integer, default: 1

    add_index :posts, :status
    change_column_null :posts, :status, false
  end
end
