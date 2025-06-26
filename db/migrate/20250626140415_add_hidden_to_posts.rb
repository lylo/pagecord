class AddHiddenToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :hidden, :boolean, default: false, null: false
  end
end
